-- Returns the system-wide theme name, shared with wezterm and tmux.
-- Written by the `theme` command (.scripts/theme in .system-config).
return function()
  local file = io.open(vim.fn.expand("~/.config/theme/current"), "r")
  if not file then
    return "rose-pine"
  end
  local name = file:read("*l")
  file:close()
  name = name and vim.trim(name) or ""
  return name ~= "" and name or "rose-pine"
end
