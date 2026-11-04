-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true

-- The colorscheme and background follow the system-wide theme selected with
-- the `theme` command (see .scripts/theme); the state files are watched so
-- switching recolors open windows immediately.
local function read_state(name, default)
	local path = wezterm.home_dir .. "/.config/theme/" .. name
	wezterm.add_to_config_reload_watch_list(path)
	local f = io.open(path, "r")
	if not f then
		return default
	end
	local value = (f:read("*l") or ""):gsub("%s+", "")
	f:close()
	return value ~= "" and value or default
end

local theme = read_state("current", "rose-pine")
local transparent = read_state("background", "transparent") ~= "opaque"

-- nightowl: Night Owl navy backgrounds with a neon "coolnight" ANSI palette
if theme == "nightowl" then
	config.colors = {
		foreground = "#CBE0F0",
		background = "#011423",
		cursor_bg = "#47FF9C",
		cursor_border = "#47FF9C",
		cursor_fg = "#011423",
		selection_bg = "#033259",
		selection_fg = "#CBE0F0",
		ansi = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#0FC5ED", "#a277ff", "#24EAF7", "#24EAF7" },
		brights = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#A277FF", "#a277ff", "#24EAF7", "#24EAF7" },
	}
elseif theme == "tokyonight" then
	config.color_scheme = "tokyonight_night"
else -- rose-pine
	config.color_scheme = "rose-pine-moon"
	-- slightly darker background than rose-pine moon's base (matches nvim/tmux)
	config.colors = { background = "#1f1d2e" }
end

config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 14

config.enable_tab_bar = false

config.window_decorations = "RESIZE"
-- Translucent, blurred background so the wallpaper shows through, unless
-- switched with `theme <name> opaque`. Only cells painted with the default
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
