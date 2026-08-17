import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components

// Popups on the focused monitor, top right, like swaync's positionX/positionY.
PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: Notifications.popups.length > 0

    anchors {
        top: true
        right: true
    }

    margins {
        top: 6
        right: 6
    }

    implicitWidth: 500
    implicitHeight: Math.max(1, column.implicitHeight)
    exclusiveZone: 0
    color: "transparent"

    // Only the cards take clicks; the gaps between them stay click-through.
    mask: Region {
        item: column
    }

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 12

        Repeater {
            model: Notifications.popups

            NotificationCard {
                id: card

                required property var modelData

                // Evaluated once per delegate; recreation resumes the countdown
                // from the entry's deadline instead of restarting it.
                readonly property int remaining: card.entry.expiresAt > 0 ? Math.max(1, card.entry.expiresAt - Date.now()) : 0

                entry: modelData
                Layout.fillWidth: true

                onDismissed: Notifications.dismiss(card.entry)
                onActionInvoked: Notifications.dropPopup(card.entry)

                Timer {
                    interval: card.remaining
                    running: card.remaining > 0
                    onTriggered: Notifications.dropPopup(card.entry)
                }
            }
        }
    }
}
