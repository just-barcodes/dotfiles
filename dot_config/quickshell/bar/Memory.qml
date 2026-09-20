import Quickshell.Hyprland
import qs

// Memory warning chip: hidden until usage passes SystemStats.memoryWarnPercent,
// then shown red like the critical temperature chip. Click focuses the btop
// workspace, as the old always-on waybar module did.
BarChip {
    visible: SystemStats.memoryUsage > SystemStats.memoryWarnPercent
    filled: true
    color: Theme.red
    text: "\u{f0c9} " + SystemStats.memoryUsage + "%"
    textColor: Theme.bg

    onLeftClicked: Hyprland.dispatch("hl.dsp.focus({workspace = 99, on_current_monitor = true})")
}
