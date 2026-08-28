import QtQuick
import qs

// waybar `custom/notification`. In-process, so the `qs ipc call notifs status`
// exec and the `pkill -RTMIN+8 waybar` push that fed it both fall away.
BarChip {
    id: root

    // Set by Bar.qml.
    property var controlCenter: null

    readonly property int count: Notifications.count
    readonly property bool dnd: Notifications.dnd

    text: (root.dnd ? "\u{f009b}" : "\u{f009a}") + " " + root.count
    textColor: root.count > 0 ? Theme.peach : Theme.fgFaint

    onLeftClicked: root.controlCenter?.toggle()
    onRightClicked: Notifications.toggleDnd()
}
