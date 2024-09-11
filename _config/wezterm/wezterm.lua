local wezterm = require 'wezterm'
return {
    color_scheme = "Homebrew",

    -- tab bar
    use_fancy_tab_bar = false,
    hide_tab_bar_if_only_one_tab = true,
    tab_bar_at_bottom = true,

    -- window
    window_decorations = 'RESIZE',
    window_background_opacity = 0.7,
    text_background_opacity = 0.7,
    macos_window_background_blur = 70,
    window_padding = {
	left = 15,
	right = 15,
	top = 15,
	bottom = 5,
    },

    -- font
    font = wezterm.font_with_fallback {
       {
          family = "FiraCode Nerd Font",
          harfbuzz_features = {"calt=1", "clig=1", "liga=0"},
       },
       "PingFang SC"
    },
    font_size = 16,
    adjust_window_size_when_changing_font_size = false,
}
