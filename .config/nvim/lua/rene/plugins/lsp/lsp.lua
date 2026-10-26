return {
  "hrsh7th/cmp-nvim-lsp",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    {
      "antosha417/nvim-lsp-file-operations",
      -- TODO: unpin once upstream fixes the log rotation timer from 1303184, which
      -- asserts the logfile exists and errors 30s after startup when nothing was logged yet
      commit = "cab4c48a69d8b11301a8326013effc2f382144c0",
      config = true,
    },
    { "folke/lazydev.nvim", opts = {} },
  },
  config = function()
    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = cmp_nvim_lsp.default_capabilities()

    vim.lsp.config("*", {
      capabilities = capabilities,
    })
  end,
}
