import Quickshell.Wayland
import qs

// waybar `idle_inhibitor`. Quickshell binds zwp_idle_inhibitor_v1 directly —
// the same protocol waybar used — so this is the real inhibitor, not a proxy
// for it: hyprland stops reporting the session idle at all, rather than
// hypridle being talked out of acting on it.
//
// The protocol attaches the inhibitor to a surface, hence the window.
BarChip {
    id: root

    required property var barWindow

    text: inhibitor.enabled ? "\u{f033e}" : "\u{f0335}"
    color: inhibitor.enabled ? Theme.yellow : Theme.chipBg
    textColor: inhibitor.enabled ? Theme.bg : Theme.fg

    onLeftClicked: inhibitor.enabled = !inhibitor.enabled

    IdleInhibitor {
        id: inhibitor

        window: root.barWindow
        enabled: false
    }
}
