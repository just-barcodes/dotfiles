import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs

// waybar `tray`. Quickshell only displays StatusNotifier items; nm-applet, the
// tailscale agent and the rest still provide them.
Rectangle {
    id: root

    // The bar window, which item.display() needs as the menu's parent.
    required property var barWindow

    color: Theme.chipBg
    implicitWidth: row.implicitWidth + Theme.barChipPadding * 2
    implicitHeight: Theme.barChipHeight

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 10

        Repeater {
            // The ObjectModel directly, not `.values`: a `property var` array of
            // live objects is the shape that costs delegates their identity.
            model: SystemTray.items

            delegate: Item {
                id: entry

                required property var modelData

                implicitWidth: 20
                implicitHeight: 20
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.fill: parent
                    source: entry.modelData.icon
                    sourceSize.width: 20
                    sourceSize.height: 20
                    fillMode: Image.PreserveAspectFit
                    // `#tray > .passive { opacity: 0.7 }`
                    opacity: entry.modelData.status === Status.Passive ? 0.7 : 1
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: 7
                    color: Theme.red
                    z: -1
                    visible: entry.modelData.status === Status.NeedsAttention
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: event => {
                        if (event.button === Qt.MiddleButton) {
                            entry.modelData.secondaryActivate();
                            return;
                        }
                        // Right click, and left click on a menu-only item, both
                        // want the DBus menu rather than Activate.
                        if (event.button === Qt.RightButton || entry.modelData.onlyMenu) {
                            if (entry.modelData.hasMenu)
                                entry.modelData.display(root.barWindow, entry.width / 2, root.height);
                            return;
                        }
                        entry.modelData.activate();
                    }
                }
            }
        }
    }
}
