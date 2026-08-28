import QtQuick
import Quickshell
import qs
import qs.bar

// The top bar, one window per monitor. Covers every waybar module except
// keyboard-state, which needs an evdev read Wayland does not offer.
Scope {
    id: root

    // The shell objects the modules act on, passed down rather than reached
    // for through `qs ipc call`, which is what waybar has to do.
    property var osd: null
    property var controlCenter: null
    property var networkPanel: null

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData

            screen: win.modelData
            color: "transparent"
            implicitHeight: Theme.barHeight

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                top: Theme.barMarginTop
                left: Theme.barMarginSide
                right: Theme.barMarginSide
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.barBg
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 3
                anchors.verticalCenter: parent.verticalCenter

                Workspaces {
                    screenName: win.modelData.name
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                Sessions {}

                // `#custom-sm { margin-right: 24px }`
                Item {
                    implicitWidth: 24
                    implicitHeight: 1
                }

                Memory {}

                Cpu {}

                Temperature {}

                PowerProfileToggle {}
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 3
                anchors.verticalCenter: parent.verticalCenter

                // `#idle_inhibitor { margin: 3px 6px }`
                IdleInhibitor {
                    barWindow: win
                }

                Item {
                    implicitWidth: 6
                    implicitHeight: 1
                }

                Battery {}

                Audio {
                    osd: root.osd
                }

                NetworkStatus {
                    panel: root.networkPanel
                }

                Clock {}

                Bell {
                    controlCenter: root.controlCenter
                }

                Tray {
                    barWindow: win
                }
            }
        }
    }
}
