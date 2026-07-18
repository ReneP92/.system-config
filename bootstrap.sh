#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y-%m-%d_%H%M%S)"

DRY_RUN=false
NO_BREW=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --no-brew) NO_BREW=true ;;
    *)
      echo "Usage: $0 [--dry-run] [--no-brew]" >&2
      exit 1
      ;;
  esac
done

linked=0
skipped=0
backed_up=0

run() {
  if $DRY_RUN; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

# Symlink $HOME/<rel> -> $REPO_DIR/<rel>, backing up anything already there.
link_file() {
  local src="$1" rel="$2"
  local target="$HOME/$rel"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
    echo "  skip:   ~/$rel (already linked)"
    skipped=$((skipped + 1))
    return
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "  backup: ~/$rel -> $BACKUP_DIR/$rel"
    run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    run mv "$target" "$BACKUP_DIR/$rel"
    backed_up=$((backed_up + 1))
  fi

  echo "  link:   ~/$rel -> $src"
  run mkdir -p "$(dirname "$target")"
  run ln -s "$src" "$target"
  linked=$((linked + 1))
}

clone_if_missing() {
  local url="$1" dest="$2"
  if [ -e "$dest" ]; then
    echo "  skip:   $dest (already exists)"
  else
    echo "  clone:  $url -> $dest"
    run git clone "$url" "$dest"
  fi
}

# Directories linked as a whole: files added inside them later are picked
# up automatically, without re-running this script.
LINK_DIRS=(
  ".config/nvim"
)

# --- Symlinks -----------------------------------------------------------
# Every dot-prefixed file at the repo root is linked to the same relative
# path in $HOME. Apart from LINK_DIRS, directories (e.g. .config) are never
# linked themselves -- their files are linked one by one, so unmanaged
# content in ~/.config stays untouched.
echo "==> Linking dotfiles from $REPO_DIR"

prune_dirs=()
for rel in "${LINK_DIRS[@]}"; do
  link_file "$REPO_DIR/$rel" "$rel"
  prune_dirs+=(-o -path "$REPO_DIR/$rel")
done

# Non-dotfiles linked explicitly: shared agent instructions, wired into
# each agent's expected global path.
link_file "$REPO_DIR/AGENTS.md" "AGENTS.md"
link_file "$REPO_DIR/AGENTS.md" ".claude/CLAUDE.md"

while IFS= read -r src; do
  link_file "$src" "${src#"$REPO_DIR"/}"
done < <(find "$REPO_DIR" \( -name .git -o -name settings.local.json -o -name .gitignore -o -name .DS_Store "${prune_dirs[@]}" \) -prune -o -type f -path "$REPO_DIR/.*" -print | sort)

# --- Homebrew packages --------------------------------------------------
if ! $NO_BREW; then
  echo "==> Installing Homebrew packages"
  if command -v brew >/dev/null 2>&1; then
    run brew bundle --file="$REPO_DIR/Brewfile"
  else
    echo "  Homebrew not found. Install it from https://brew.sh, then run:"
    echo "  brew bundle --file=$REPO_DIR/Brewfile"
  fi
fi

# --- External repos -----------------------------------------------------
echo "==> Cloning external dependencies"
clone_if_missing https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
clone_if_missing https://github.com/junegunn/fzf-git.sh.git "$HOME/fzf-git.sh"
clone_if_missing https://github.com/tmux-plugins/tpm.git "$HOME/.tmux/plugins/tpm"

# --- Summary ------------------------------------------------------------
echo
echo "==> Done: $linked linked, $skipped skipped, $backed_up backed up"
if [ "$backed_up" -gt 0 ] && ! $DRY_RUN; then
  echo "    Backups saved to $BACKUP_DIR"
fi
