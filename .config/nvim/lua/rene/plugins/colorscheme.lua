-- The active colorscheme follows the system-wide theme selected with the
-- `theme` command (see .scripts/theme); both plugins stay installed and
-- `cond` picks which one loads.
local theme = require("rene.theme")()

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
          transparency = false,
        },
        palette = {
          moon = {
            base = "#1f1d2e", -- slightly darker background (matches wezterm/tmux)
          },
        },
        highlight_groups = {
          -- hide the ~ end-of-buffer markers (fg matches the bg)
          EndOfBuffer = { fg = "#1f1d2e" },
          -- darker background for the nvim-tree sidebar
          NvimTreeNormal = { bg = "#191724" },
          NvimTreeNormalNC = { bg = "#191724" },
          NvimTreeEndOfBuffer = { bg = "#191724", fg = "#191724" },
        },
      })

      vim.cmd("colorscheme rose-pine")
    end,
  },
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    cond = theme == "tokyonight",
    config = function()
      local transparent = false -- set to true if you would like to enable transparency

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
        styles = {
          sidebars = transparent and "transparent" or "dark",
          floats = transparent and "transparent" or "dark",
        },
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
}
