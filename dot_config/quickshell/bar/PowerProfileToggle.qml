import QtQuick
import Quickshell.Services.UPower
import qs

// waybar `power-profiles-daemon`. Backed by the UPower service rather than a
// `powerprofilesctl` shell-out; `PowerProfiles.profile` is writable.
BarChip {
    id: root

    readonly property int profile: PowerProfiles.profile
    readonly property bool performance: root.profile === PowerProfile.Performance

    filled: root.performance
    color: root.performance ? Theme.peach : "transparent"

    text: {
        if (root.performance)
            return "\u{f0874}";
        if (root.profile === PowerProfile.PowerSaver)
            return "\u{f0873}";
        return "\u{f029a}";
    }
    textColor: {
        if (root.performance)
            return Theme.bg;
        return root.profile === PowerProfile.Balanced ? Theme.sapphire : Theme.fg;
    }

    // waybar cycles on click; skip Performance where ppd does not offer it.
    onLeftClicked: {
        const cycle = PowerProfiles.hasPerformanceProfile ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced];
        const next = (cycle.indexOf(root.profile) + 1) % cycle.length;
        PowerProfiles.profile = cycle[next];
    }
}
