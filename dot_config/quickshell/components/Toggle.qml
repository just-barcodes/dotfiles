import QtQuick
import qs

// The switch from ControlCenter's Do Not Disturb row, used by the Wi-Fi and
// Bluetooth headers. `interactive` rather than the inherited `enabled` so the
// dimmed-but-present look (rfkill, no adapter) does not also disable children.
Rectangle {
    id: root

    property bool checked: false
    property bool interactive: true

    signal toggled

    implicitWidth: 44
    implicitHeight: 24
    radius: Theme.radiusSmall
    color: root.checked ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5) : Theme.control
    border.width: 1
    border.color: Theme.border
    opacity: root.interactive ? 1 : 0.4

    Rectangle {
        x: root.checked ? parent.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 18
        implicitHeight: 18
        radius: Theme.radiusSmall
        color: Theme.accent

        Behavior on x {
            NumberAnimation {
                duration: 100
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        onClicked: root.toggled()
    }
}
