-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true

-- The colors and background follow the system-wide theme selected with the
-- `theme` command (see .scripts/theme). The state files are watched, so
-- switching recolors open windows immediately.
local state_dir = wezterm.home_dir .. "/.config/theme/"

local function read_state(name, default)
	local path = state_dir .. name
	wezterm.add_to_config_reload_watch_list(path)
	local f = io.open(path, "r")
	if not f then
		return default
	end
	local value = (f:read("*l") or ""):gsub("%s+", "")
	f:close()
	return value ~= "" and value or default
end

-- The active theme's palette: palette.conf links to themes/<name>.conf in
-- the repo, a list of THEME_KEY="value" lines shared with tmux and fzf.
local function read_palette()
	local path = state_dir .. "palette.conf"
	wezterm.add_to_config_reload_watch_list(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local palette = {}
	for line in f:lines() do
		local key, value = line:match('^THEME_([%w_]+)="([^"]*)"')
		if key then
			palette[key] = value
		end
	end
	f:close()
	return palette
end

local palette = read_palette()
local transparent = read_state("background", "transparent") ~= "opaque"

if palette and palette.BG then
	local ansi, brights = {}, {}
	for i = 0, 7 do
		ansi[i + 1] = palette["ANSI_" .. i]
		brights[i + 1] = palette["ANSI_" .. (i + 8)]
	end
	config.colors = {
		foreground = palette.FG,
		background = palette.BG,
		cursor_bg = palette.CURSOR_BG,
		cursor_border = palette.CURSOR_BG,
		cursor_fg = palette.CURSOR_FG,
		selection_bg = palette.SELECTION_BG,
		selection_fg = palette.SELECTION_FG,
		ansi = ansi,
		brights = brights,
	}
else
	-- no theme selected yet (bootstrap.sh seeds palette.conf): rose-pine
	config.color_scheme = "rose-pine-moon"
	config.colors = { background = "#1f1d2e" }
end

config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 14

config.enable_tab_bar = false

config.window_decorations = "RESIZE"
-- Translucent, blurred background so the wallpaper shows through, unless
-- switched with `theme background opaque`. Only cells painted with the default
-- background are see-through, so nvim, tmux and fzf then use the terminal
-- default instead of an explicit bg color.
if transparent then
	config.window_background_opacity = 0.85
	config.macos_window_background_blur = 20
end

-- Send the CSI-u sequence for Shift+Enter (key 13, modifier 2) so TUIs like
-- opencode, whose default input_newline includes shift+return, can tell it
-- apart from a plain Enter and insert a newline instead of submitting.
config.keys = {
	{
		key = "Enter",
		mods = "SHIFT",
		action = wezterm.action.SendString("\x1b[13;2u"),
	},
}

-- and finally, return the configuration to wezterm
return config
