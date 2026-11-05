#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y-%m-%d_%H%M%S)"

DRY_RUN=false
NO_BREW=false
SKILLS_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --no-brew) NO_BREW=true ;;
    --skills-only) SKILLS_ONLY=true ;;
    *)
      echo "Usage: $0 [--dry-run] [--no-brew] [--skills-only]" >&2
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

# Put brew on PATH if it is installed but not yet in this shell's PATH
# (e.g. a fresh Mac where shellenv hasn't been set up). Returns 1 if
# Homebrew is not installed at all.
ensure_brew() {
  command -v brew >/dev/null 2>&1 && return 0
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then
      eval "$("$candidate" shellenv)"
      return 0
    fi
  done
  return 1
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
  ".config/opencode/plugins/tmux-agent-status"
)

# Link skill folders rather than individual SKILL.md files: Cursor's skill
# scanner skips file symlinks. Folder links also include new references.
link_agent_skills() {
  local src
  for src in "$REPO_DIR/.claude/skills/"*; do
    [ -e "$src" ] || continue
    link_file "$src" "${src#"$REPO_DIR"/}"
  done
}

# Install just the shared skills and OpenCode slash-command adapters. All
# three agents discover ~/.claude/skills; their workflows have one source.
if $SKILLS_ONLY; then
  echo "==> Linking shared agent skills from $REPO_DIR"
  link_agent_skills
  while IFS= read -r src; do
    link_file "$src" "${src#"$REPO_DIR"/}"
  done < <(find "$REPO_DIR/.config/opencode/commands" -type f -print | sort)
  echo "==> Done: $linked linked, $skipped skipped, $backed_up backed up"
  if [ "$backed_up" -gt 0 ] && ! $DRY_RUN; then
    echo "    Backups saved to $BACKUP_DIR"
  fi
  exit 0
fi

# --- Preflight ----------------------------------------------------------
# Fail before touching anything, so a missing Homebrew doesn't leave a
# half-bootstrapped machine.
if ! $NO_BREW && ! ensure_brew; then
  echo "Error: Homebrew is not installed." >&2
  echo "  Install it from https://brew.sh, then re-run $0" >&2
  echo "  (or pass --no-brew to skip package installation)" >&2
  exit 1
fi

# --- Symlinks -----------------------------------------------------------
# Every dot-prefixed file at the repo root is linked to the same relative
# path in $HOME. Apart from LINK_DIRS, directories (e.g. .config) are never
# linked themselves -- their files are linked one by one, so unmanaged
# content in ~/.config stays untouched.
echo "==> Linking dotfiles from $REPO_DIR"

# Retire only our old V1 plugin link after moving to a V2 plugin directory.
legacy_plugin=".config/opencode/plugins/tmux-agent-status.js"
if [ -L "$HOME/$legacy_plugin" ] && [ "$(readlink "$HOME/$legacy_plugin")" = "$REPO_DIR/$legacy_plugin" ]; then
  run unlink "$HOME/$legacy_plugin"
fi

# Retire our old tmux palette links; the palettes moved to themes/ in the
# repo, read through ~/.config/theme/palette.conf (seeded below).
for legacy_palette in "$HOME"/.tmux/themes/*.conf; do
  if [ -L "$legacy_palette" ] && [ "$(readlink "$legacy_palette")" = "$REPO_DIR/.tmux/themes/$(basename "$legacy_palette")" ]; then
    run unlink "$legacy_palette"
  fi
done
if [ -d "$HOME/.tmux/themes" ] && [ -z "$(ls -A "$HOME/.tmux/themes")" ]; then
  run rmdir "$HOME/.tmux/themes"
fi

link_agent_skills
prune_dirs=(-o -path "$REPO_DIR/.claude/skills")
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
done < <(find "$REPO_DIR" \( -name .git -o -name settings.local.json -o -name 'settings.json.bak*' -o -name settings.json.lock -o -name 'settings.json.tmp.*' -o -name .gitignore -o -name .DS_Store "${prune_dirs[@]}" \) -prune -o -type f -path "$REPO_DIR/.*" -print | sort)

# --- Theme --------------------------------------------------------------
# Claude Code's settings.json selects the custom theme "active", which the
# `theme` command (.scripts/theme) rewrites on every switch. Seed it from the
# current theme so a fresh machine has one before the first switch.
echo "==> Seeding the theme"
claude_active="$HOME/.claude/themes/active.json"
if [ -e "$claude_active" ]; then
  echo "  skip:   ~/.claude/themes/active.json (already exists)"
else
  current_theme="$(cat "$HOME/.config/theme/current" 2>/dev/null || echo rose-pine)"
  [ -r "$REPO_DIR/assets/claude-themes/$current_theme.json" ] || current_theme=rose-pine
  echo "  seed:   ~/.claude/themes/active.json ($current_theme)"
  run mkdir -p "$(dirname "$claude_active")"
  run cp "$REPO_DIR/assets/claude-themes/$current_theme.json" "$claude_active"
fi

# wezterm, tmux and fzf read the active palette through this link, which
# the `theme` command repoints on every switch. Seed it the same way.
palette_link="$HOME/.config/theme/palette.conf"
if [ -e "$palette_link" ]; then
  echo "  skip:   ~/.config/theme/palette.conf (already exists)"
else
  current_theme="$(cat "$HOME/.config/theme/current" 2>/dev/null || echo rose-pine)"
  [ -r "$REPO_DIR/themes/$current_theme.conf" ] || current_theme=rose-pine
  echo "  seed:   ~/.config/theme/palette.conf ($current_theme)"
  run mkdir -p "$(dirname "$palette_link")"
  run ln -sfn "$REPO_DIR/themes/$current_theme.conf" "$palette_link"
  # the palette used to be linked here for tmux alone
  run rm -f "$HOME/.config/theme/tmux-current.conf"
fi

# The background used to be stored as transparent/opaque; wezterm, tmux,
# nvim and fzf now read translucent/solid.
background_state="$HOME/.config/theme/background"
case "$(cat "$background_state" 2>/dev/null || true)" in
  transparent) legacy_background=translucent ;;
  opaque) legacy_background=solid ;;
  *) legacy_background="" ;;
esac
if [ -n "$legacy_background" ]; then
  echo "  migrate: ~/.config/theme/background ($legacy_background)"
  if ! $DRY_RUN; then
    printf '%s\n' "$legacy_background" >"$background_state"
  fi
fi

# --- Homebrew packages --------------------------------------------------
if ! $NO_BREW; then
  echo "==> Installing Homebrew packages"
  run brew bundle --file="$REPO_DIR/Brewfile"
fi

# --- External repos -----------------------------------------------------
echo "==> Cloning external dependencies"
clone_if_missing https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
clone_if_missing https://github.com/junegunn/fzf-git.sh.git "$HOME/fzf-git.sh"
clone_if_missing https://github.com/tmux-plugins/tpm.git "$HOME/.tmux/plugins/tpm"

# --- tmux plugins -------------------------------------------------------
# tpm only clones the plugins listed in .tmux.conf when asked to; without
# this, bindings like vim-tmux-navigator's C-h/j/k/l silently don't exist.
echo "==> Installing tmux plugins"
run "$HOME/.tmux/plugins/tpm/bin/install_plugins"

# --- Standalone binaries ------------------------------------------------
echo "==> Installing standalone binaries"
if command -v treehouse >/dev/null 2>&1; then
  echo "  skip:   treehouse (already installed)"
elif $DRY_RUN; then
  echo "  [dry-run] curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh"
else
  echo "  install: treehouse"
  curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh
fi

if command -v cursor-agent >/dev/null 2>&1 || [ -x "$HOME/.local/bin/cursor-agent" ]; then
  echo "  skip:   Cursor CLI (already installed)"
elif $DRY_RUN; then
  echo "  [dry-run] curl https://cursor.com/install -fsS | bash"
else
  echo "  install: Cursor CLI"
  curl https://cursor.com/install -fsS | bash
fi

# --- Summary ------------------------------------------------------------
echo
echo "==> Done: $linked linked, $skipped skipped, $backed_up backed up"
if [ "$backed_up" -gt 0 ] && ! $DRY_RUN; then
  echo "    Backups saved to $BACKUP_DIR"
fi
