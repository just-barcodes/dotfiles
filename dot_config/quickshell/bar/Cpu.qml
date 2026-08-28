import Quickshell.Hyprland
import qs

// waybar `cpu`. Blank until SystemStats has two samples to difference.
BarChip {
    filled: false
    text: SystemStats.cpuUsage < 0 ? "" : "\u{f061a} " + String(SystemStats.cpuUsage).padStart(2, " ") + "%"
    textColor: Theme.sapphire

    onLeftClicked: Hyprland.dispatch("hl.dsp.focus({workspace = 99, on_current_monitor = true})")
}
