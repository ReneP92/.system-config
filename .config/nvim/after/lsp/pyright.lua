local function configure_venv(new_config, root_dir)
  -- Find .venv directory starting from the project root
  local venv_path = vim.fs.find(".venv", {
    path = root_dir,
    upward = false,
    type = "directory",
  })[1]

  if venv_path then
    -- Extract the directory containing .venv (project root)
    local project_root = vim.fs.dirname(venv_path)
    -- Determine the Python interpreter path
    local python_exe = vim.fn.has("win32") == 1 and "python.exe" or "python"
    local path_sep = vim.fn.has("win32") == 1 and "\\" or "/"
    local python_path
    -- On Windows, the path would be Scripts/python.exe, otherwise bin/python
    if vim.fn.has("win32") == 1 then
      python_path = venv_path .. path_sep .. "Scripts" .. path_sep .. python_exe
    else
      python_path = venv_path .. path_sep .. "bin" .. path_sep .. python_exe
    end

    -- Check if the Python interpreter exists
    if vim.fn.filereadable(python_path) == 0 then
      python_path = nil
    end

    -- Merge with existing settings
    new_config.settings = new_config.settings or {}
    new_config.settings.python = new_config.settings.python or {}
    -- Use absolute paths to ensure Pyright can find them
    new_config.settings.python.venvPath = vim.fn.fnamemodify(project_root, ":p")
    new_config.settings.python.venv = ".venv"
    if python_path then
      new_config.settings.python.pythonPath = vim.fn.fnamemodify(python_path, ":p")
    end
  end
end

-- Try using on_new_config first (preferred method)
local config = {
  on_new_config = function(new_config, root_dir)
    configure_venv(new_config, root_dir)
  end,
}

-- Fallback: Also set up an autocmd to update settings after client attaches
-- This ensures settings are applied even if on_new_config isn't called
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("PyrightVenvConfig", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.name == "pyright" then
      local root_dir = client.config.root_dir or vim.fn.getcwd()
      configure_venv(client.config, root_dir)
      -- Notify the server of the updated settings
      client.notify("workspace/didChangeConfiguration", {
        settings = client.config.settings,
      })
    end
  end,
})

return config
