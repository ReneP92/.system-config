return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      python = { "ruff" },
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    local function file_in_cwd(file_name)
      return vim.fs.find(file_name, {
        upward = true,
        stop = vim.loop.cwd():match("(.+)/"),
        path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
        type = "file",
      })[1]
    end

    local function remove_linter(linters, linter_name)
      for k, v in pairs(linters) do
        if v == linter_name then
          linters[k] = nil
          break
        end
      end
    end

    local function copy_linters(linters)
      if type(linters) ~= "table" then
        return linters
      end

      local copy = {}
      for i, v in ipairs(linters) do
        copy[i] = v
      end
      return copy
    end

    local function lsp_client_attached(bufnr, needle)
      local target = (needle or ""):lower()
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        local name = (client.name or ""):lower()
        if name == target or name:find(target, 1, true) then
          return true
        end
      end
      return false
    end

    local function linter_in_linters(linters, linter_name)
      for k, v in pairs(linters) do
        if v == linter_name then
          return true
        end
      end
      return false
    end

    local function remove_linter_if_missing_config_file(linters, linter_name, config_file_name)
      if linter_in_linters(linters, linter_name) and not file_in_cwd(config_file_name) then
        remove_linter(linters, linter_name)
      end
    end

    local function try_linting()
      local linters = copy_linters(lint.linters_by_ft[vim.bo.filetype])

      -- Avoid duplicate diagnostics when Ruff is provided by an LSP client.
      if vim.bo.filetype == "python" and linters then
        if lsp_client_attached(0, "ruff") then
          remove_linter(linters, "ruff")

          -- If Ruff linting already ran before the LSP attached, its diagnostics can
          -- linger and appear duplicated alongside LSP diagnostics. Clear them.
          local ok, ns = pcall(function()
            return lint.get_namespace and lint.get_namespace("ruff") or nil
          end)
          if ok and ns then
            vim.diagnostic.reset(ns, 0)
          end
        end
      end

      -- if linters then
      --   -- remove_linter_if_missing_config_file(linters, "eslint_d", ".eslintrc.cjs")
      --   remove_linter_if_missing_config_file(linters, "eslint_d", "eslint.config.js")
      -- end

      lint.try_lint(linters)
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        try_linting()
      end,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = lint_augroup,
      callback = function()
        -- Re-evaluate linters after clients attach to prevent Ruff duplicates.
        try_linting()
      end,
    })

    vim.keymap.set("n", "<leader>l", function()
      try_linting()
    end, { desc = "Trigger linting for current file" })
  end,
}
