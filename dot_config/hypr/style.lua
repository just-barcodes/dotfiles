-- Look and feel
-- https://wiki.hypr.land/Configuring/Basics/Variables/

local p = require("palette")

hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 1,

        border_size = 3,

        col = {
            active_border   = p.rgba("cyan", "ee"),
            inactive_border = p.rgba("bg_2", "aa"),
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 3,
        rounding_power = 2,

        dim_inactive = true,
        dim_strength = 0.12,

        shadow = {
            enabled = false,
        },

        blur = {
            enabled = false,
        },
    },

    animations = {
        enabled = false,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },

    group = {
        -- Keep one group per workspace: new and moved-in windows auto-join.
        auto_group               = true,
        group_on_movetoworkspace = true,
        col = {
            border_active          = p.rgba("cyan", "ee"),
            border_inactive        = p.rgba("bg_2", "aa"),
            border_locked_active   = p.rgba("yellow", "ee"),
            border_locked_inactive = p.rgba("bg_2", "aa"),
        },
        groupbar = {
            enabled                    = true,
            height                     = 26,
            font_family                = "FiraCode Nerd Font",
            font_size                  = 14,
            gradients                  = true,
            render_titles              = true,
            stacked                    = false,
            rounding                   = 0,
            round_only_edges           = false,
            gradient_rounding          = 0,
            gradient_round_only_edges  = false,
            keep_upper_gap             = false,
            gaps_in                    = 0,
            gaps_out                   = 0,
            text_padding               = 8,
            text_offset                = 0,
            indicator_height           = 0,
            indicator_gap              = 0,
            text_color                 = p.rgb("bg_0"),
            text_color_inactive        = p.rgb("fg_0"),
            text_color_locked_active   = p.rgb("bg_0"),
            text_color_locked_inactive = p.rgb("fg_0"),
            font_weight_active         = "bold",
            font_weight_inactive       = "bold",
            col = {
                active          = p.rgba("cyan", "ff"),
                inactive        = p.rgba("bg_2", "ff"),
                locked_active   = p.rgba("yellow", "ff"),
                locked_inactive = p.rgba("bg_2", "ff"),
            },
        },
    },
})

-- "Smart gaps" / "No gaps when only": drop border, rounding, and gaps
-- when a workspace has a single tiled or fullscreen window.
-- `s[false]` excludes special workspaces so special:magic keeps its red border.
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]s[false]",   gaps_out = 0, gaps_in = 0 })
hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]s[false]" }, border_size = 0, rounding = 0 })
hl.window_rule({ name = "no-gaps-f1",   match = { float = false, workspace = "f[1]s[false]"   }, border_size = 0, rounding = 0 })
