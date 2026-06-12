-- Hyprland config entry point
-- https://wiki.hypr.land/Configuring/Start/

------------------
---- INCLUDES ----
------------------
-- monitors.lua is machine-local and not tracked by chezmoi; tolerate it missing.
pcall(require, "monitors")
require("style")
require("input")
require("keybindings")
require("workspaces")


-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("waybar")               -- status bar
    hl.exec_cmd("swaync")               -- notifications
    hl.exec_cmd("elephant")             -- backend for walker
    hl.exec_cmd("walker --gapplication-service")  -- improve walker start-up time
    hl.exec_cmd("ghostty -e btop", { workspace = "99" })
    hl.dispatch(hl.dsp.focus({ workspace = 4, on_current_monitor = true }))
    hl.exec_cmd("systemctl --user start hyprpolkitagent")  -- authentication daemon
    hl.exec_cmd("hypridle")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("tailscale systray")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE",         "24")
hl.env("HYPRCURSOR_SIZE",      "24")


-----------------------
----- PERMISSIONS -----
-----------------------
-- Permission changes require a Hyprland restart; not applied on-the-fly for security.
-- hl.config({ ecosystem = { enforce_permissions = true } })
-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Ignore maximize requests from all apps.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Red border on the named special workspace, always visible — the no-gaps
-- single-window rules in style.lua are scoped `s[false]` so they don't zero
-- the border on special:magic. String form is "<active> <inactive>".
hl.window_rule({
    name  = "special-magic-border",
    match = { workspace = "special:magic" },
    border_color = "rgba(fa5750ee) rgba(2d5b69aa)",
})

-- Firefox/Zen extension pop-out windows (e.g., Bitwarden) and Picture-in-Picture
hl.window_rule({
    name  = "float-firefox-extensions",
    match = {
        class = "^(firefox|firefox-developer-edition|zen-alpha|zen)$",
        title = "^(Extension:.*)$",
    },
    float = true,
})
hl.window_rule({
    name  = "float-firefox-bitwarden",
    match = {
        class = "^(firefox|firefox-developer-edition|zen-alpha|zen)$",
        title = ".*Bitwarden.*",
    },
    float = true,
})
hl.window_rule({
    name  = "float-picture-in-picture",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
})

-- Betterbird/Thunderbird reminder & calendar alert popups
hl.window_rule({
    name  = "float-betterbird-reminders",
    match = {
        class = "^(eu\\.betterbird\\.Betterbird|thunderbird)$",
        title = "^(Reminders?)$",
    },
    float = true,
})
hl.window_rule({
    name  = "float-betterbird-alarms",
    match = {
        class = "^(eu\\.betterbird\\.Betterbird|thunderbird)$",
        title = ".*(Alarm|Reminder).*",
    },
    float = true,
})

-- Authentication / polkit prompts
hl.window_rule({
    name  = "float-polkit",
    match = { class = "^(hyprpolkitagent|polkit-gnome-authentication-agent-1|org\\.kde\\.polkit-kde-authentication-agent-1)$" },
    float = true,
})

-- Common system dialogs
hl.window_rule({
    name  = "float-system-dialogs",
    match = { class = "^(pavucontrol|org\\.pulseaudio\\.pavucontrol|blueman-manager|nm-connection-editor|file-roller)$" },
    float = true,
})

-- Generic file/save dialogs (GTK/Qt portal)
hl.window_rule({
    name  = "float-portal-dialogs",
    match = { class = "^(xdg-desktop-portal-gtk|xdg-desktop-portal-kde)$" },
    float = true,
})
hl.window_rule({
    name  = "float-file-save-dialogs",
    match = { title = "^(Open File|Save File|Save As|Save Image|Choose Files?|Select File)$" },
    float = true,
})
