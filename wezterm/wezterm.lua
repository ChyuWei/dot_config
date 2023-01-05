local wezterm = require 'wezterm'
return {
    color_scheme = "Homebrew",

    -- tab bar
    use_fancy_tab_bar = false,
    hide_tab_bar_if_only_one_tab = true,
    tab_bar_at_bottom = true,

    window_background_opacity = 0.7,
    text_background_opacity = 0.7,

    font = wezterm.font({
        family = "FiraCode Nerd Font",
        harfbuzz_features = {"calt=1", "clig=1", "liga=0"},
    }),
    font_size = 14.5,
}
