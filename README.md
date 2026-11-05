# .system-config

Personal config files. Every dot-prefixed file at the repo root is symlinked to the same path in `~` (e.g. `.zshrc` → `~/.zshrc`, `.claude/settings.json` → `~/.claude/settings.json`), so edits in the repo apply immediately and changes are tracked by git. Files inside directories like `.config/` and `.claude/` are linked individually, leaving unmanaged content in those directories untouched - except for the directories in `LINK_DIRS` (currently `.config/nvim` and `.config/opencode/plugins/tmux-agent-status`) and each managed `.claude/skills/<name>` folder, which are symlinked as a whole so new files inside them are covered automatically.

## Setup

```
git clone https://github.com/ReneP92/.system-config.git ~/Projects/personal/.system-config
cd ~/Projects/personal/.system-config
./bootstrap.sh
```

Requires [Homebrew](https://brew.sh) unless `--no-brew` is passed - the script exits before changing anything if it is missing.

The script:

- symlinks all dotfiles into `~` - anything already there is moved to `~/.dotfiles-backup/<timestamp>/` first
- installs all Homebrew packages from the `Brewfile` (codex, claude-code, docker-desktop, wezterm, maccy, rectangle, font-meslo-lg-nerd-font, tmux, neovim, node, go, fzf, ripgrep, eza, bat, chafa, fd, zoxide, gh, git-delta, lazygit, lazydocker, tree, tlrc, zsh-autosuggestions, zsh-syntax-highlighting)
- clones external dependencies if missing:
  - [powerlevel10k](https://github.com/romkatv/powerlevel10k) → `~/powerlevel10k`
  - [fzf-git.sh](https://github.com/junegunn/fzf-git.sh) → `~/fzf-git.sh`
  - [tpm](https://github.com/tmux-plugins/tpm) → `~/.tmux/plugins/tpm`
- installs the tmux plugins listed in `.tmux.conf` via tpm (vim-tmux-navigator, tmux-resurrect, tmux-continuum)
- installs [Bun](https://bun.sh/) through Homebrew
- installs standalone binaries if missing:
  - [treehouse](https://kunchenguid.github.io/treehouse) via `curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh`

The nvim config lives in this repo at `.config/nvim` and is linked as a whole directory to `~/.config/nvim`.

Flags: `--dry-run` previews all actions without changing anything, `--no-brew` skips package installation, and `--skills-only` installs just the shared agent skills and OpenCode commands without requiring Homebrew or running other setup steps. Re-running is safe - anything already linked is skipped.

To add a new config file, place it in the repo (dot-prefixed, at the path it should have relative to `~`) and re-run `./bootstrap.sh`.

## Shared agent skills

Eleven gstack-inspired skills live in `.claude/skills/` and are linked into `~/.claude/skills/`. Claude Code, OpenCode and Cursor CLI discover that global directory. Each managed skill is linked as a whole folder because Cursor skips individually symlinked `SKILL.md` files. Other installed skills remain untouched. OpenCode slash-command adapters live in `.config/opencode/commands/`; the workflows themselves have one canonical copy.

Install or refresh only these files:

```sh
./bootstrap.sh --skills-only --dry-run
./bootstrap.sh --skills-only
```

| Command | Purpose |
| --- | --- |
| `/plan-eng-review` | Architecture, technical plans, edge cases and verification strategy |
| `/eng-review` | Code correctness, security and production readiness |
| `/investigate` | End-user reproduction and systematic root-cause debugging |
| `/qa` | Functional testing for browsers, APIs, CLIs, jobs and webhooks |
| `/ship` | Final validation, documentation and requested commit/PR delivery |
| `/spec` | Code-grounded requirements and testable acceptance criteria |
| `/office-hours` | Product discovery and competing technical approaches |
| `/design-review` | Visual polish, accessibility and interaction quality |
| `/devex-review` | Developer onboarding, tooling ergonomics and diagnostics |
| `/careful` | Advisory review of potentially destructive operations |
| `/test-audit` | Test value, duplication, flakiness and meaningful coverage |

Use `/eng-review` instead of `/review` to avoid built-in command collisions, including Cursor's review command. Examples: `/qa test the import CLI`, `/eng-review --fix`, `/design-review --report-only`. Reviews and QA report by default; request fixes explicitly or use `--fix` where supported. `/ship` is explicitly invoked, and other skills can be selected by the agent when their descriptions fit the task.

All skills respect the active agent/mode restrictions. Specs stay in chat unless a file or issue is requested; issue filing can use GitHub or Linear. Shipping follows repository-native release automation, does not manually edit changelogs/generated files, and never adds the agent as a co-author. `/careful` is guidance only, with no blocking hooks or persistent safety mode.

After installing, use Claude Code's `/reload-skills` if the new directory is not yet visible, OpenCode's `/reload` if needed, or a fresh Cursor CLI session. OpenCode also supports explicit skill mentions such as `@eng-review`. Project definitions can shadow these skills according to each host's precedence rules.

These are locally maintained adaptations, not a full gstack installation. They use available native tools without a required browser package, external reviewer, telemetry or auto-updater. Upstream provenance and the MIT license are recorded in `.claude/skills/NOTICE.txt` and `.claude/skills/LICENSE.txt`. Review upstream improvements selectively and update the recorded revision when incorporating them.

## Agent tmux status

Claude Code, Cursor CLI and OpenCode share the per-pane tmux activity indicator: an animated spinner while busy, a bell when waiting for input, and no icon when idle.

Cursor CLI uses `.cursor/hooks.json` and `.cursor/tmux-status.sh` to mark prompt submission as busy and clear the indicator on completion, cancellation, error or session exit. Session startup also clears stale state. Cursor currently exposes no permission-wait hook, so permission prompts retain the busy indicator. Bootstrap links both files into `~/.cursor/`; start a fresh Cursor CLI session after installing them.

### OpenCode

The V2 plugin in `.config/opencode/plugins/tmux-agent-status/` updates the shared tmux agent indicator from the terminal client. It aggregates open tabs (or the current session family when tabs are off), prioritizes pending questions/permissions, and clears the indicator on unload or exit. The shared server only provides plugin discovery, so other terminals cannot overwrite this pane's state. This integration targets the full-screen TUI.

Re-run `./bootstrap.sh --no-brew` when upgrading from the old single-file plugin. Bootstrap removes the old managed symlink and links the new plugin directory. OpenCode reloads plugins automatically; `/reload` forces a refresh if needed. Run the status regression tests with `node --test tests/tmux-agent-status.test.mjs`.

## Switching themes

WezTerm, tmux, nvim, fzf, Claude Code and the macOS wallpaper share one color theme, switched with the `theme` command (`.scripts/theme`, on `PATH` via `.zshrc`). Run plain `theme` to pick one interactively:

- the list shows the available themes, starting on the current one
- the preview shows each theme's colors on a mock tmux status bar, code and fzf list, its 16 terminal colors and its wallpaper (thumbnails need `chafa`, from the `Brewfile`)
- the whole terminal window and the tmux status bar recolor live while moving through the list
- the top line chooses the background: `tab` (or `ctrl-b`) flips between translucent and solid, and the window shows the choice live
- `enter` switches, and `esc` restores the colors and background you had

The other commands (`theme help` lists them, and zsh completes them when its completion system is loaded):

```
theme set tokyonight             # switch theme, keeping the background
theme tokyonight                 # the same, shorter
theme set nightowl --solid       # switch and use solid backgrounds
theme background toggle          # flip translucent / solid (also: translucent, solid)
theme current                    # print the current theme
theme list                       # list the themes, marking the current one
theme preview rose-pine          # render a theme's preview in the terminal
```

By default the background is translucent: WezTerm's window is see-through and blurred, so the wallpaper shows through, and nvim, tmux and fzf paint the terminal's default background instead of their own. Solid gives every app its theme background instead. A switch keeps the current background unless `--translucent` or `--solid` is given. The older names `opaque` and `transparent` still work.

Each theme is one palette file, `themes/<name>.conf`, the single source of truth for the terminal colors, the tmux status bar roles and the fzf colors. It holds `THEME_KEY="value"` lines, so bash can source it, tmux can `source-file` it and `.wezterm.lua` parses it. The command links the active one to `~/.config/theme/palette.conf` and stores the name in `~/.config/theme/current` and the background (`translucent` or `solid`) in `~/.config/theme/background`. Each app reads them:

- **WezTerm** builds its colors from `palette.conf` and watches the state, so open windows recolor immediately. While the picker is open, it previews the background through a `THEME_BACKGROUND` user var that `.wezterm.lua` applies as a window override
- **tmux** is reloaded by the command and sources `palette.conf` for the status bar colors. `.tmux.conf` allows passthrough and a larger input buffer, which the picker's live recolor and wallpaper thumbnails need
- **nvim** reads the name on startup, so already running instances keep their theme until restarted
- **fzf** colors are set by `.zshrc` from `palette.conf`, so new shells pick up a switch
- **Claude Code** uses the custom theme `custom:active` (set in `.claude/settings.json`). The command copies `assets/claude-themes/<name>.json` to `~/.claude/themes/active.json`, which running sessions hot-reload (sessions started before `~/.claude/themes/` existed need one restart). `.zshrc` sets `CLAUDE_CODE_TMUX_TRUECOLOR=1`, because Claude Code otherwise drops to 256-color approximations inside tmux

On macOS, switching themes also sets the desktop wallpaper on every display and Space to `assets/wallpapers/<name>-dark-wallpaper-2560x1440.png`, with matching images for `rose-pine`, `nightowl` and `tokyonight`. The `theme` script reads palettes, wallpapers and Claude Code themes straight from the repo, so no extra link is needed. macOS may ask for permission to control System Events the first time the wallpaper is applied.

To add a theme:

1. Create `themes/<name>.conf` with the same keys as the existing ones (`tests/theme.test.mjs` checks that none is missing).
2. Add a Claude Code palette as `assets/claude-themes/<name>.json` (a [custom theme](https://code.claude.com/docs/en/terminal-config.md#create-a-custom-theme) with `base` and `overrides`).
3. Add its macOS wallpaper as `assets/wallpapers/<name>-dark-wallpaper-2560x1440.png`.
4. Add a colorscheme plugin with `cond = theme == "<name>"` in `.config/nvim/lua/rene/plugins/colorscheme.lua`, or extend the `cond` of an existing spec when reusing its plugin, as `tokyonight` and `nightowl` do.

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
