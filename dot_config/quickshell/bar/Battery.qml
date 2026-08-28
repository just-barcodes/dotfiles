import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs

// waybar `battery`. UPower reports `percentage` as a 0..1 fraction, not the
// 0..100 waybar prints.
BarChip {
    id: root

    // Referenced declaratively so the UPower singleton is constructed at load.
    // Reaching for it first from inside a handler yields a service that has not
    // talked to DBus yet.
    readonly property var device: UPower.displayDevice
    readonly property int capacity: Math.round((root.device ? root.device.percentage : 0) * 100)
    readonly property bool charging: root.device && (root.device.state === UPowerDeviceState.Charging || root.device.state === UPowerDeviceState.PendingCharge)
    readonly property bool full: root.device && root.device.state === UPowerDeviceState.FullyCharged

    readonly property var icons: ["\u{f244}", "\u{f243}", "\u{f242}", "\u{f241}", "\u{f240}"]
    readonly property string icon: root.icons[Math.min(root.icons.length - 1, Math.floor(root.capacity / 100 * root.icons.length))]

    visible: root.device !== null && root.device.isLaptopBattery

    text: {
        if (root.full)
            return "\u{f240} ";
        const pct = String(root.capacity).padStart(3, " ") + "%";
        return root.charging ? "\u{26a1}" + pct : root.icon + pct;
    }

    // states: warning 30, critical 15
    readonly property bool warning: root.capacity <= 30 && root.capacity > 15 && !root.charging
    readonly property bool critical: root.capacity <= 15 && !root.charging

    color: root.critical ? Theme.red : (root.warning ? Theme.yellow : Theme.chipBg)
    textColor: (root.critical || root.warning) ? Theme.bg : Theme.sapphire
}
