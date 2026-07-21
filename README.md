# .system-config

Personal config files. Every dot-prefixed file at the repo root is symlinked to the same path in `~` (e.g. `.zshrc` → `~/.zshrc`, `.claude/settings.json` → `~/.claude/settings.json`), so edits in the repo apply immediately and changes are tracked by git. Files inside directories like `.config/` and `.claude/` are linked individually, leaving unmanaged content in those directories untouched — except for the directories in `LINK_DIRS` (currently `.config/nvim`), which are symlinked as a whole so new files inside them are covered automatically.

## Setup

```
git clone https://github.com/ReneP92/.system-config.git ~/Projects/personal/.system-config
cd ~/Projects/personal/.system-config
./bootstrap.sh
```

The script:

- symlinks all dotfiles into `~` — anything already there is moved to `~/.dotfiles-backup/<timestamp>/` first
- installs all Homebrew packages from the `Brewfile` (codex, wezterm, opensuperwhisper, tmux, neovim, fzf, eza, bat, fd, git-delta, tree, tlrc, zsh-autosuggestions, zsh-syntax-highlighting)
- clones external dependencies if missing:
  - [powerlevel10k](https://github.com/romkatv/powerlevel10k) → `~/powerlevel10k`
  - [fzf-git.sh](https://github.com/junegunn/fzf-git.sh) → `~/fzf-git.sh`
  - [tpm](https://github.com/tmux-plugins/tpm) → `~/.tmux/plugins/tpm`

The nvim config lives in this repo at `.config/nvim` and is linked as a whole directory to `~/.config/nvim`.

Flags: `--dry-run` previews all actions without changing anything, `--no-brew` skips package installation. Re-running is safe — anything already linked is skipped.

To add a new config file, place it in the repo (dot-prefixed, at the path it should have relative to `~`) and re-run `./bootstrap.sh`.

---

# Tool reference

### tldr

```
tldr eza
```

### fzf (fuzzy finder)

| Example                              | Description                    |
| ------------------------------------ | ------------------------------ |
| `CTRL-t`                             | Look for files and directories |
| `CTRL-r`                             | Look through command history   |
| `Enter`                              | Select the item                |
| `Ctrl-j` or `Ctrl-n` or `Down arrow` | Go down one result             |
| `Ctrl-k` or `Ctrl-p` or `Up arrow`   | Go up one result               |
| `Tab`                                | Mark a result                  |
| `Shift-Tab`                          | Unmark a result                |

### fzf-git

| Keybind   | Description                    |
| --------- | ------------------------------ |
| `CTRL-GF` | Look for git files with fzf    |
| `CTRL-GB` | Look for git branches with fzf |

### git-delta

Better diffs for `git show` / `git diff`.

### tmux

| command | Description |
|---|---|
| `tmux` | Activate tmux session |
| `tmux kill-session -a` | Kill all but current tmux session |

Windows
| command | Description |
|---|---|
| `ctrl-a c` | Create a new window |
| `crtl-a ,` | Rename current window |
| `ctrl-a &` | Close current window |
| `ctrl-a w` | List all current windows |
| `ctrl-a p` | Go to previous window |
| `ctrl-a n` | Go to next window |

Panes
| command | Description |
|---|---|
| `ctrl-a \|` | Split pane vertically |
| `ctrl-a -` | Split pane horizontally |
| `ctrl-a →/←` | Navigate to left / right panel |
| `ctrl-a ↑/↓` | Navigate to upper / lower panel |
