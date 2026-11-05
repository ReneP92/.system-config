-- System-wide theme state, shared with wezterm, tmux and fzf.
-- Written by the `theme` command (.scripts/theme in .system-config).
local M = {}

local function read(path)
  local file = io.open(vim.fn.expand(path), "r")
  if not file then
    return ""
  end
  local value = file:read("*l")
  file:close()
  return value and vim.trim(value) or ""
end

-- The theme name (rose-pine | nightowl | tokyonight), rose-pine by default.
function M.name()
  local name = read("~/.config/theme/current")
  return name ~= "" and name or "rose-pine"
end

-- Whether backgrounds should be left transparent so wezterm's translucent
-- window shows through (the default); `theme background solid` turns it off.
function M.transparent()
  return read("~/.config/theme/background") ~= "solid"
end

return M
