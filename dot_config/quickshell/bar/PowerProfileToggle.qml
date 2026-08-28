import QtQuick
import Quickshell.Services.UPower
import qs

// waybar `power-profiles-daemon`. Backed by the UPower service rather than a
// `powerprofilesctl` shell-out; `PowerProfiles.profile` is writable.
BarChip {
    id: root

    readonly property int profile: PowerProfiles.profile

    filled: false

    text: {
        if (root.profile === PowerProfile.Performance)
            return "\u{f0874}";
        if (root.profile === PowerProfile.PowerSaver)
            return "\u{f0873}";
        return "\u{f029a}";
    }
    textColor: root.profile === PowerProfile.Balanced ? Theme.sapphire : Theme.fg

    // waybar cycles on click; skip Performance where ppd does not offer it.
    onLeftClicked: {
        const cycle = PowerProfiles.hasPerformanceProfile ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced];
        const next = (cycle.indexOf(root.profile) + 1) % cycle.length;
        PowerProfiles.profile = cycle[next];
    }
}
