import QtQuick
import Quickshell
import Quickshell.Networking
import qs

// waybar `network`. Left click opens the existing NetworkPanel; right click
// keeps the wifitui escape hatch for enterprise networks and VPNs.
BarChip {
    id: root

    // Set by Bar.qml.
    property var panel: null

    readonly property var devices: Networking.devices ? Networking.devices.values : []
    readonly property var wifi: root.devices.find(d => d.type === DeviceType.Wifi) ?? null
    // DeviceType calls it Wired, and hasLink lives on WiredDevice.
    readonly property var wired: root.devices.find(d => d.type === DeviceType.Wired && d.hasLink) ?? null

    // The device exposes no active-AP property, so the connected entry in its
    // scan list is where the SSID and signal come from.
    readonly property var accessPoint: (root.wifi?.networks?.values ?? []).find(n => n.connected) ?? null

    text: {
        if (root.wired)
            return "\u{f0c1}  " + root.wired.name;
        if (root.accessPoint)
            return "\u{f1eb} (" + Math.round((root.accessPoint.signalStrength ?? 0) * 100) + "%)";
        return "Disconnected \u{26a0}";
    }
    textColor: (root.wired || root.accessPoint) ? Theme.sapphire : Theme.red

    onLeftClicked: root.panel?.toggle()
    onRightClicked: Quickshell.execDetached(["ghostty", "--class=com.tui.centered", "-e", "wifitui"])
}
