import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components

// Right-hand panel: settings block, media player, then notification history.
// Same widget order as the swaync config it replaces, minus inhibitors.
PanelWindow {
    id: root

    property bool shown: false
    property double dismissedAt: 0

    // Clicking the waybar module while the panel is open clears the focus grab
    // (press) and then runs the toggle (release), which would reopen it. Ignore
    // an open that arrives right after a dismissal.
    function toggle() {
        if (!root.shown && Date.now() - root.dismissedAt < 300)
            return;
        root.shown = !root.shown;
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: shown

    anchors {
        top: true
        bottom: true
        right: true
    }

    implicitWidth: 500
    exclusiveZone: 0
    color: Theme.bg
    focusable: true

    // Clicking anywhere outside the panel dismisses it. The grab also keeps
    // keyboard focus here, which is what makes the shortcuts below work.
    // active is set imperatively: the compositor writes false on dismissal,
    // which would destroy a binding.
    onShownChanged: focusGrab.active = root.shown

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: {
            root.shown = false;
            root.dismissedAt = Date.now();
        }
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.shown = false;
                event.accepted = true;
            } else if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier)) {
                // Same as the Clear All button, including swaync's hide-on-clear.
                Notifications.clearAll();
                root.shown = false;
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 24
            anchors.bottomMargin: Theme.margin
            anchors.leftMargin: Theme.margin
            anchors.rightMargin: Theme.margin
            spacing: 8

            // Settings block — backlight (laptops only), volume, DND.
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: settings.implicitHeight + 2 * Theme.padding
                radius: Theme.radius
                color: Theme.surface

                ColumnLayout {
                    id: settings
                    anchors.fill: parent
                    anchors.margins: Theme.padding
                    spacing: Theme.padding

                    BacklightWidget {
                        Layout.fillWidth: true
                    }

                    VolumeWidget {
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.padding

                        Text {
                            Layout.fillWidth: true
                            text: "Do Not Disturb"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        Rectangle {
                            implicitWidth: 44
                            implicitHeight: 24
                            radius: Theme.radiusSmall
                            color: Notifications.dnd ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5) : Theme.control
                            border.width: 1
                            border.color: Theme.border

                            Rectangle {
                                x: Notifications.dnd ? parent.width - width - 3 : 3
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
                                onClicked: Notifications.toggleDnd()
                            }
                        }
                    }
                }
            }

            // Media player pill, hidden when nothing is playing.
            Rectangle {
                Layout.fillWidth: true
                visible: mpris.player !== null
                implicitHeight: mpris.implicitHeight + 2 * Theme.padding
                radius: Theme.radius
                color: Theme.surface

                MprisWidget {
                    id: mpris
                    anchors.fill: parent
                    anchors.margins: Theme.padding
                }
            }

            // Title bar
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 8
                implicitHeight: 52
                radius: Theme.radius
                color: Theme.surface

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.padding
                    spacing: Theme.padding

                    Text {
                        Layout.fillWidth: true
                        text: "Notifications"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        implicitWidth: clearText.implicitWidth + 24
                        implicitHeight: 28
                        radius: Theme.radiusSmall
                        visible: Notifications.count > 0
                        color: clearArea.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.25) : Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)

                        Text {
                            id: clearText
                            anchors.centerIn: parent
                            text: "Clear All"
                            color: Theme.red
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                Notifications.clearAll();
                                root.shown = false;  // swaync's hide-on-clear
                            }
                        }
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: Notifications.count > 0
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: Notifications.history

                        NotificationCard {
                            id: card
                            required property var modelData

                            entry: modelData
                            Layout.fillWidth: true

                            onDismissed: Notifications.dismiss(card.entry)
                            onActionInvoked: root.shown = false  // swaync's hide-on-action
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                visible: Notifications.count === 0
                text: "No notifications"
                color: Theme.fgFaint
                opacity: 0.6
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
            }
        }
    }
}
