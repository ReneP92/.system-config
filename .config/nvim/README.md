# Neovim config

Personal Neovim setup built around `lazy.nvim`, LSP, Treesitter, Telescope, and a small set of quality-of-life plugins.

Leader key: `<Space>`

## Requirements

- Neovim `0.11+` (this config uses `vim.lsp.config`)
- `git`
- A Nerd Font (icons)
- Optional but recommended:
  - `make` (builds `telescope-fzf-native` and LuaSnip’s optional regexp engine)
  - Node.js (for many LSP servers/tools like `tsserver`, `prettier`, `eslint`)

## Install

1. Back up your current config:

   ```sh
   mv ~/.config/nvim ~/.config/nvim.bak
   ```

2. Clone this repo:

   ```sh
   git clone <YOUR_REPO_URL> ~/.config/nvim
   ```

3. Start Neovim:

   ```sh
   nvim
   ```

On first launch, `lazy.nvim` bootstraps automatically and installs plugins.

## What’s included

### Core

- Sensible defaults: relative numbers, 2-space indentation, system clipboard, split behavior, no swapfile
- `jk` to exit insert mode

### LSP

- LSP keymaps attached per-buffer via `LspAttach`
- Servers installed via Mason (`mason-lspconfig`):
  - `pyright`, `ts_ls`, `html`, `cssls`, `tailwindcss`, `svelte`, `lua_ls`, `graphql`, `emmet_ls`, `prismals`, `eslint`
- Extra server tweaks in `after/lsp/*` for:
  - `eslint` (filetypes)
  - `svelte` (notify TS/JS changes on save)
  - `graphql` / `emmet_ls` (filetypes)

### Formatting

- `conform.nvim` format-on-save (with LSP fallback)
- Formatters by filetype:
  - JS/TS/JSON/YAML/Markdown/GraphQL/etc: `prettier`
  - Lua: `stylua`
  - Python: `ruff`
  - Shell: `shfmt`

### Linting

- `nvim-lint` wired to run on `BufEnter`, `BufWritePost`, `InsertLeave`
- Python: `ruff`
- Avoids duplicate diagnostics if Ruff is attached as an LSP client

### Navigation & UI

- `telescope.nvim` (+ `telescope-fzf-native`)
- `nvim-tree` file explorer
- `trouble.nvim` diagnostics/quickfix UI (Telescope integration)
- `gitsigns.nvim` hunk actions + blame
- `lualine.nvim` statusline
- `bufferline.nvim` in tab mode
- `alpha-nvim` dashboard
- `which-key.nvim` keymap discoverability
- `indent-blankline.nvim` indentation guides
- `dressing.nvim` improved UI prompts/select

### Editing helpers

- `nvim-cmp` + `LuaSnip` + `friendly-snippets` + `lspkind`
- `nvim-autopairs` integrated with completion
- Treesitter textobjects (custom captures for JS/TS in `after/queries/ecma/textobjects.scm`)
- `substitute.nvim` for quick operator/line substitutions
- `nvim-surround`
- `vim-maximizer`
- `todo-comments.nvim` (+ Telescope picker + Trouble source)

## Keymaps

### General

| Mode | Keys | Action |
| --- | --- | --- |
| Insert | `jk` | Escape |
| Normal | `<leader>nh` | Clear search highlights |
| Normal | `<leader>+` / `<leader>-` | Increment / decrement number |

### Windows / tabs

| Mode | Keys | Action |
| --- | --- | --- |
| Normal | `<leader>sv` / `<leader>sh` | Vertical / horizontal split |
| Normal | `<leader>se` | Equalize splits |
| Normal | `<leader>sx` | Close split |
| Normal | `<leader>sm` | Maximize / minimize split |
| Normal | `<leader>to` / `<leader>tx` | New tab / close tab |
| Normal | `<leader>tn` / `<leader>tp` | Next / previous tab |
| Normal | `<leader>tf` | Open current buffer in new tab |

### Telescope

| Mode | Keys | Action |
| --- | --- | --- |
| Normal | `<leader>ff` | Find files |
| Normal | `<leader>fr` | Recent files |
| Normal | `<leader>fs` | Live grep |
| Normal | `<leader>fc` | Grep word under cursor |
| Normal | `<leader>ft` | TODOs (Telescope) |
| Normal | `<leader>fk` | Keymaps |

Inside Telescope:

| Mode | Keys | Action |
| --- | --- | --- |
| Insert | `<C-j>` / `<C-k>` | Move selection |
| Insert | `<C-q>` | Send to quickfix and open Trouble |
| Insert | `<C-t>` | Open results in Trouble |

### File explorer (nvim-tree)

| Mode | Keys | Action |
| --- | --- | --- |
| Normal | `<leader>ee` | Toggle tree |
| Normal | `<leader>ef` | Locate current file in tree |
| Normal | `<leader>ec` | Collapse |
| Normal | `<leader>er` | Refresh |

### LSP (buffer-local)

| Mode | Keys | Action |
| --- | --- | --- |
| Normal | `gd` | Definition |
| Normal | `gD` | Declaration |
| Normal | `gr` | References (Telescope) |
| Normal | `gi` | Implementations (Telescope) |
| Normal | `gt` | Type definitions (Telescope) |
| Normal | `K` | Hover docs |
| Normal | `<leader>rn` | Rename |
| Normal / Visual | `<leader>ca` | Code action |
| Normal | `<leader>d` | Line diagnostics float |
| Normal | `<leader>D` | Buffer diagnostics (Telescope) |
| Normal | `[d` / `]d` | Previous / next diagnostic |
| Normal | `<leader>rs` | Restart LSP |

### Formatting / linting

| Mode | Keys | Action |
| --- | --- | --- |
| Normal / Visual | `<leader>mp` | Format file / selection |
| Normal | `<leader>l` | Lint current file |

### Git

| Mode | Keys | Action |
| --- | --- | --- |
| Normal | `<leader>lg` | LazyGit |

Gitsigns:

| Mode | Keys | Action |
| --- | --- | --- |
| Normal | `[h` / `]h` | Previous / next hunk |
| Normal / Visual | `<leader>hs` / `<leader>hr` | Stage / reset hunk |
| Normal | `<leader>hS` / `<leader>hR` | Stage / reset buffer |
| Normal | `<leader>hu` | Undo stage hunk |
| Normal | `<leader>hp` | Preview hunk |
| Normal | `<leader>hb` / `<leader>hB` | Blame line / toggle blame |
| Normal | `<leader>hd` / `<leader>hD` | Diff this / diff vs `~` |

### Trouble

| Mode | Keys | Action |
| --- | --- | --- |
| Normal | `<leader>xw` | Workspace diagnostics |
| Normal | `<leader>xd` | Document diagnostics |
| Normal | `<leader>xq` | Quickfix list |
| Normal | `<leader>xl` | Location list |
| Normal | `<leader>xt` | TODOs |

### Sessions

| Mode | Keys | Action |
| --- | --- | --- |
| Normal | `<leader>wr` | Restore session for cwd |
| Normal | `<leader>ws` | Save session for cwd |

### Substitute

| Mode | Keys | Action |
| --- | --- | --- |
| Normal | `<leader>r` | Substitute with motion |
| Normal | `<leader>rr` | Substitute line |
| Normal | `<leader>R` | Substitute to end of line |
| Visual | `<leader>r` | Substitute selection |

### TODO comments

| Mode | Keys | Action |
| --- | --- | --- |
| Normal | `[t` / `]t` | Previous / next todo |

### Treesitter textobjects

Custom selects/moves/swaps are defined in the Treesitter textobjects plugin config and `after/queries/ecma/textobjects.scm`.

## Updating

- Update plugins: `:Lazy update`
- Update Treesitter parsers: `:TSUpdate`
- Update Mason tools/servers: `:Mason` (then update/install)

## Layout

- `init.lua` loads core, plugins, and LSP keymaps/diagnostics.
- `lua/rene/core/*` editor options + general keymaps.
- `lua/rene/lazy.lua` lazy.nvim bootstrap + plugin imports.
- `lua/rene/plugins/*` plugin specs/config.
- `lua/rene/plugins/lsp/*` Mason + LSP capabilities integration.
- `after/lsp/*` per-server overrides.
- `after/queries/*` custom Treesitter queries.

## Notes

- AI plugin config exists but is currently commented out in `lua/rene/plugins/ai.lua`.
