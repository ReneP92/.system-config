-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true

-- The colorscheme follows the system-wide theme selected with the `theme`
-- command (see .scripts/theme); the state file is watched so switching
-- recolors open windows immediately.
local theme_file = wezterm.home_dir .. "/.config/theme/current"
wezterm.add_to_config_reload_watch_list(theme_file)

local theme = "rose-pine"
local f = io.open(theme_file, "r")
if f then
	local name = (f:read("*l") or ""):gsub("%s+", "")
	f:close()
	if name ~= "" then
		theme = name
	end
end

if theme == "tokyonight" then
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
else -- rose-pine
	config.color_scheme = "rose-pine-moon"
	-- slightly darker background than rose-pine moon's base (matches nvim/tmux)
	config.colors = { background = "#1f1d2e" }
end

config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 14

config.enable_tab_bar = false

config.window_decorations = "RESIZE"
-- config.window_background_opacity = 0.8
-- config.macos_window_background_blur = 10

-- and finally, return the configuration to wezterm
return config
