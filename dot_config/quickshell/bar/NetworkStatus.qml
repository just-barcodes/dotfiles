import QtQuick
import Quickshell
import Quickshell.Io
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

    // Proton VPN names its NetworkManager connection "ProtonVPN <server>" under
    // every protocol backend (the interface name varies: OpenVPN lands on
    // `tun0`), so an active connection with that prefix is the connection
    // state. Cheaper than the panel's `protonvpn status`, which is too slow to
    // poll from an always-visible chip.
    property bool vpnConnected: false

    text: {
        const icon = root.vpnConnected ? "\u{f099d}" : null;
        if (root.wired)
            return (icon ?? "\u{f0c1}") + "  " + root.wired.name;
        if (root.accessPoint)
            return (icon ?? "\u{f1eb}") + " (" + Math.round((root.accessPoint.signalStrength ?? 0) * 100) + "%)";
        return "Disconnected \u{26a0}";
    }
    textColor: (root.wired || root.accessPoint) ? Theme.sapphire : Theme.red

    onLeftClicked: root.panel?.toggle()
    onRightClicked: Quickshell.execDetached(["ghostty", "--class=com.tui.centered", "-e", "wifitui"])

    Process {
        id: vpnProbe
        command: ["sh", "-c", "nmcli -g NAME connection show --active | grep -q '^ProtonVPN '"]
        onExited: code => root.vpnConnected = code === 0
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: vpnProbe.running = true
    }
}
