import Quickshell.Hyprland
import qs

// waybar `memory`. Click focuses the btop workspace, as it did there.
BarChip {
    filled: false
    text: "\u{f0c9}" + String(SystemStats.memoryUsage).padStart(3, " ") + "%"
    textColor: Theme.sapphire

    onLeftClicked: Hyprland.dispatch("hl.dsp.focus({workspace = 99, on_current_monitor = true})")
}
