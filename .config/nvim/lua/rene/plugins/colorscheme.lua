-- The active colorscheme follows the system-wide theme selected with the
-- `theme` command (see .scripts/theme); all plugins stay installed and
-- `cond` picks which one loads.
local theme_state = require("rene.theme")
local theme = theme_state.name()
-- translucent unless switched with `theme background solid`
local transparent = theme_state.transparent()

-- background styles for the tokyonight-derived themes (tokyonight itself,
-- and lumon/hackerman, which are built on the same engine)
local tokyonight_styles = {
  sidebars = transparent and "transparent" or "dark",
  floats = transparent and "transparent" or "dark",
}

-- `transparent` alone still paints the statusline/winbar/tabline (and
-- lualine/bufferline, which derive from them) with bg_statusline in the
-- tokyonight-derived themes
local function clear_statusline_bg(colors)
  if transparent then
    colors.bg_statusline = colors.none
  end
end

-- Drop the background of the groups that paint the editor area, gutter
-- (including its signs), splits, bars, float titles and sidebar, keeping their
-- other attributes. Colorscheme transparency options differ in what they clear
-- (some keep the statusline, the gutter or the separators painted), so
-- translucent themes finish with this to match the fully clear look of
-- rose-pine and tokyonight. Groups without a background are left alone, so
-- links and plugins' default links stay intact.
local function clear_backgrounds()
  for _, group in ipairs({
    "Normal",
    "NormalNC",
    "NormalFloat",
    "FloatBorder",
    "FloatTitle",
    "SignColumn",
    "FoldColumn",
    "LineNr",
    "CursorLineNr",
    "EndOfBuffer",
    "WinSeparator",
    "VertSplit",
    "StatusLine",
    "StatusLineNC",
    "TabLineFill",
    "WinBar",
    "WinBarNC",
    "GitSignsAdd",
    "GitSignsChange",
    "GitSignsDelete",
    "DiagnosticSignError",
    "DiagnosticSignWarn",
    "DiagnosticSignInfo",
    "DiagnosticSignHint",
    "NvimTreeNormal",
    "NvimTreeNormalNC",
    "NvimTreeEndOfBuffer",
    "NvimTreeWinSeparator",
    -- nvim-tree maps its window's StatusLine(NC) to these
    "NvimTreeStatusLine",
    "NvimTreeStatusLineNC",
  }) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    if hl.bg then
      hl.bg = "NONE"
      vim.api.nvim_set_hl(0, group, hl)
    end
  end
end

-- Apply a colorscheme, then clear its backgrounds when translucent. Options:
--   fg          foreground overrides by group, for colors too dark to read on
--               the background (taken from the theme's Omarchy palette)
--   own_winbar  for colorschemes that leave WinBar undefined, which would
--               otherwise keep nvim's default near-black bar on dropbar's
--               row: gives the winbar the editor background instead
local function apply_colorscheme(colorscheme, opts)
  opts = opts or {}
  vim.cmd.colorscheme(colorscheme)
  for group, fg in pairs(opts.fg or {}) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    hl.fg = fg
    vim.api.nvim_set_hl(0, group, hl)
  end
  if transparent then
    clear_backgrounds()
  elseif opts.own_winbar then
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    vim.api.nvim_set_hl(0, "WinBar", { fg = normal.fg, bg = normal.bg })
    vim.api.nvim_set_hl(0, "WinBarNC", { link = "WinBar" })
  end
end

return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    cond = theme == "rose-pine",
    config = function()
      require("rose-pine").setup({
        dark_variant = "moon",
        dim_inactive_windows = false,
        extend_background_behind_borders = false,
        styles = {
          italic = false,
          transparency = transparent,
        },
        palette = {
          moon = {
            base = "#1f1d2e", -- slightly darker background (matches wezterm/tmux)
          },
        },
        highlight_groups = transparent
            and {
              -- `transparency` leaves the winbar (dropbar's row) painted
              WinBar = { bg = "NONE" },
              WinBarNC = { link = "WinBar" },
            }
          or {
            -- darker background for the nvim-tree sidebar
            NvimTreeNormal = { bg = "#191724" },
            NvimTreeNormalNC = { bg = "#191724" },
            NvimTreeEndOfBuffer = { bg = "#191724", fg = "#191724" },
          },
      })

      vim.cmd("colorscheme rose-pine")
    end,
  },
  -- tokyonight.nvim backs two themes (one spec, since lazy.nvim merges specs
  -- for the same plugin):
  --   tokyonight: the stock "night" style
  --   nightowl:   "night" syntax highlighting with its background and UI
  --               colors swapped for a Night Owl style navy palette
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    cond = theme == "tokyonight" or theme == "nightowl",
    config = function()
      if theme == "tokyonight" then
        require("tokyonight").setup({
          style = "night",
          transparent = transparent,
          styles = tokyonight_styles,
          on_colors = clear_statusline_bg,
        })
        vim.cmd("colorscheme tokyonight")
        return
      end

      local bg = "#011628"
      local bg_dark = "#011423"
      local bg_highlight = "#143652"
      local bg_search = "#0A64AC"
      local bg_visual = "#275378"
      local fg = "#CBE0F0"
      local fg_dark = "#B4D0E9"
      local fg_gutter = "#627E97"
      local border = "#547998"

      require("tokyonight").setup({
        style = "night",
        transparent = transparent,
        styles = tokyonight_styles,
        on_colors = function(colors)
          colors.bg = bg
          colors.bg_dark = transparent and colors.none or bg_dark
          colors.bg_float = transparent and colors.none or bg_dark
          colors.bg_highlight = bg_highlight
          colors.bg_popup = bg_dark
          colors.bg_search = bg_search
          colors.bg_sidebar = transparent and colors.none or bg_dark
          colors.bg_statusline = transparent and colors.none or bg_dark
          colors.bg_visual = bg_visual
          colors.border = border
          colors.fg = fg
          colors.fg_dark = fg_dark
          colors.fg_float = fg
          colors.fg_gutter = fg_gutter
          colors.fg_sidebar = fg_dark
        end,
      })

      vim.cmd("colorscheme tokyonight")
    end,
  },

  -- Themes ported from Omarchy (github.com/basecamp/omarchy), using the
  -- colorscheme plugin each Omarchy theme ships in its neovim.lua
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    cond = theme == "catppuccin",
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = transparent,
        float = { transparent = transparent },
      })
      apply_colorscheme("catppuccin")
    end,
  },
  {
    "neanias/everforest-nvim",
    priority = 1000,
    cond = theme == "everforest",
    config = function()
      require("everforest").setup({
        background = "medium",
        transparent_background_level = transparent and 2 or 0,
      })
      apply_colorscheme("everforest")
    end,
  },
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    cond = theme == "gruvbox",
    config = function()
      require("gruvbox").setup({ transparent_mode = transparent })
      apply_colorscheme("gruvbox")
    end,
  },
  {
    "rebelot/kanagawa.nvim",
    priority = 1000,
    cond = theme == "kanagawa",
    config = function()
      require("kanagawa").setup({
        theme = "wave",
        transparent = transparent,
        -- `transparent` keeps the gutter (and the signs in it) painted
        colors = { theme = { all = { ui = { bg_gutter = transparent and "none" or nil } } } },
      })
      apply_colorscheme("kanagawa-wave")
    end,
  },
  {
    "EdenEast/nightfox.nvim",
    priority = 1000,
    cond = theme == "nord",
    config = function()
      require("nightfox").setup({ options = { transparent = transparent } })
      apply_colorscheme("nordfox")
    end,
  },
  {
    "tahayvr/matteblack.nvim",
    priority = 1000,
    cond = theme == "matte-black",
    config = function()
      -- matteblack has no transparency option; `apply_colorscheme` clears it
      apply_colorscheme("matteblack", { own_winbar = true, fg = { LineNr = "#555555" } })
    end,
  },
  {
    "omacom/lumon.nvim",
    priority = 1000,
    cond = theme == "lumon",
    config = function()
      require("lumon").setup({
        transparent = transparent,
        styles = tokyonight_styles,
        -- lumon.nvim's editor background is lighter than the Omarchy palette's
        -- terminal one, which would frame nvim in WezTerm's padding
        colors = { bg = "#16242d", bg_dark = "#101b21" },
        on_colors = clear_statusline_bg,
      })
      apply_colorscheme("lumon", { fg = { Comment = "#4d6f8c" } })
    end,
  },
  {
    -- a palette for aether.nvim, which takes the options
    "bjarneo/hackerman.nvim",
    dependencies = { { "omacom/aether.nvim", branch = "v3" } },
    priority = 1000,
    cond = theme == "hackerman",
    config = function()
      require("aether").setup({
        transparent = transparent,
        styles = tokyonight_styles,
        on_colors = clear_statusline_bg,
      })
      apply_colorscheme("hackerman")
    end,
  },
  {
    "OldJobobo/retro-82.nvim",
    priority = 1000,
    cond = theme == "retro-82",
    config = function()
      require("retro82").setup({ transparent = transparent })
      apply_colorscheme("retro-82", {
        fg = { Comment = "#2a6b78", ["@comment.documentation"] = "#2a6b78" },
      })
    end,
  },
  {
    "ficd0/ashen.nvim",
    priority = 1000,
    cond = theme == "solitude",
    config = function()
      require("ashen").setup({
        transparent = transparent,
        -- the Omarchy palette's terminal background, so solid nvim matches it
        colors = { background = "#101315", black = "#101315" },
      })
      apply_colorscheme("ashen", { own_winbar = true, fg = { LineNr = "#4b4e55" } })
    end,
  },
}
