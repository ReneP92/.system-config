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

-- The theme name (one of themes/<name>.conf in .system-config), rose-pine by
-- default.
function M.name()
  local name = read("~/.config/theme/current")
  return name ~= "" and name or "rose-pine"
end

-- Whether backgrounds should be left transparent so wezterm's translucent
-- window shows through (the default); `theme background solid` turns it off.
function M.transparent()
  return read("~/.config/theme/background") ~= "solid"
end

-- The terminal background (THEME_BG) of the active palette, or nil before a
-- theme was ever selected.
function M.background()
  local file = io.open(vim.fn.expand("~/.config/theme/palette.conf"), "r")
  if not file then
    return nil
  end
  for line in file:lines() do
    local value = line:match('^THEME_BG="(#%x+)"')
    if value then
      file:close()
      return value
    end
  end
  file:close()
  return nil
end

return M
