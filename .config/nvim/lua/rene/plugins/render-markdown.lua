return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = "markdown",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    heading = {
      -- nerd font md-numeric_N_box_multiple: filled for H1, outline for
      -- H2-H6; the outline codepoints are not sequential for levels 4
      -- and 5, this order is correct
      icons = { "󰼏 ", "󰎨 ", "󰎫 ", "󰎲 ", "󰎯 ", "󰎴 " },
    },
    -- no latex parser or converter (utftex/latex2text) installed
    latex = { enabled = false },
  },
}
