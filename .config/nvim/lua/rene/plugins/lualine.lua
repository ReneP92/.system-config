return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status") -- to configure lazy pending updates count

    -- Follows the active colorscheme. With a translucent background, the
    -- middle sections (c, and x, which mirrors it) and inactive statuslines
    -- are cleared like the rest of nvim, since some colorschemes' lualine
    -- themes paint them regardless of their transparency option. The theme
    -- is resolved once here, which is fine since theme switches need an nvim
    -- restart anyway.
    local function theme()
      local theme_state = require("rene.theme")
      if not theme_state.transparent() then
        return "auto"
      end

      -- For colorschemes without a lualine theme, lualine generates one from
      -- the Normal background, which translucency cleared: it would fall back
      -- to pure black blocks. Lend it the terminal background meanwhile.
      local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
      local background = theme_state.background()
      if background and not normal.bg then
        vim.api.nvim_set_hl(0, "Normal", vim.tbl_extend("force", normal, { bg = background }))
      end
      package.loaded["lualine.themes.auto"] = nil
      local auto = require("lualine.themes.auto")
      vim.api.nvim_set_hl(0, "Normal", normal)

      -- builds new tables: lualine's generated theme shares section tables
      -- between modes (inactive is normal), so editing in place would clear
      -- the mode blocks too
      local cleared = {}
      for mode, sections in pairs(auto) do
        cleared[mode] = {}
        for name, colors in pairs(sections) do
          local clear = mode == "inactive" or name == "c" or name == "x"
          cleared[mode][name] = vim.tbl_extend("force", colors, clear and { bg = "NONE" } or {})
        end
      end
      return cleared
    end

    lualine.setup({
      options = {
        theme = theme(),
      },
      sections = {
        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
            color = { fg = "#ff9e64" },
          },
          { "encoding" },
          { "fileformat", symbols = { unix = "" } },
          { "filetype" },
        },
      },
    })
  end,
}
