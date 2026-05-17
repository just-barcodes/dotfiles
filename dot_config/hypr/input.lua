-- Input
-- https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        repeat_delay = 300,

        touchpad = {
            natural_scroll      = false,
            clickfinger_behavior = true,
            tap_to_click        = false,
        },
    },
})
