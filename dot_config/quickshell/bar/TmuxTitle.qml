import Quickshell.Hyprland
import qs

// The session name of the focused tmux window, taken from the title tmux sets
// to `#S|#W` via set-titles-string. Anything else is left blank so the chip
// only shows for terminals running tmux. Names are cut so a long one cannot
// run into the centre group.
BarChip {
    readonly property string title: Hyprland.activeToplevel?.title ?? ""
    readonly property var parts: title.match(/^([^|]+\S)\|(\S[^|]+)$/)
    readonly property int maxSessionLength: 25

    function shorten(s: string): string {
        return s.length > maxSessionLength ? s.slice(0, maxSessionLength - 1) + "…" : s;
    }

    filled: false
    text: parts ? "\u{ebc8} " + shorten(parts[1]) : ""
    textColor: Theme.fgDim
}
