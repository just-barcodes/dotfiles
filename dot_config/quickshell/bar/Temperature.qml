import Quickshell.Hyprland
import qs

// waybar `temperature`, with its critical-threshold of 80. That threshold was
// dead before: the configured hwmon path did not exist, so the reading was the
// ACPI zone rather than the CPU package. SystemStats resolves the package
// sensor by name, so 80 can now actually be reached.
BarChip {
    id: root

    readonly property bool critical: SystemStats.temperature >= 80

    filled: root.critical
    color: root.critical ? Theme.red : "transparent"
    text: "\u{f2c9} " + Math.round(SystemStats.temperature) + "\u{b0}C"
    textColor: root.critical ? Theme.bg : Theme.sapphire

    onLeftClicked: Hyprland.dispatch("hl.dsp.focus({workspace = 99, on_current_monitor = true})")
}
