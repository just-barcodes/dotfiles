import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

// waybar `hyprland/workspaces`. The icon map is the one from modules.jsonc,
// minus its hair-space padding: that existed to fake centring inside GTK
// buttons, and the fixed button width here does the job properly.
Rectangle {
    id: root

    // The monitor this instance of the bar is on, so each bar shows its own
    // workspaces the way waybar does with `all-outputs` off.
    required property string screenName

    readonly property var icons: ({
            "1": "[h]",
            "2": "[j]",
            "3": "[k]",
            "4": "\u{f059f}",
            "50": "\u{ebc8}",
            "60": "\u{f0a1e}",
            "70": "\u{f082e}",
            "80": "\u{ec1e}",
            "90": "\u{f0e0}",
            "91": "\u{f02bb}",
            "95": "\u{f16a}",
            "96": "\u{1f3b5}",
            "98": "\u{f308}",
            "99": "\u{f21e}"
        })

    // Plain data, not the live HyprlandWorkspace objects: objects handed to a
    // Repeater through a `property var` array come back as copies, so the
    // delegate cannot call methods on them. Actions re-resolve by id instead.
    readonly property var rows: (Hyprland.workspaces ? Hyprland.workspaces.values : []).filter(w => w.id > 0 && (!w.monitor || w.monitor.name === root.screenName)).sort((a, b) => a.id - b.id).map(w => ({
                id: w.id,
                icon: root.icons[String(w.id)] ?? "?",
                active: w.active,
                urgent: w.urgent
            }))

    color: Theme.chipBg
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barChipHeight

    Row {
        id: row

        anchors.centerIn: parent

        Repeater {
            model: root.rows

            delegate: Item {
                id: button

                required property var modelData
                required property int index

                implicitWidth: Math.max(Theme.barWorkspaceWidth, label.implicitWidth + 16)
                implicitHeight: Theme.barChipHeight

                Rectangle {
                    anchors.fill: parent
                    color: button.modelData.active ? Theme.accent : (button.modelData.urgent ? Theme.red : "transparent")
                    opacity: button.modelData.urgent && !button.modelData.active ? 0.7 : 1
                }

                Text {
                    id: label

                    anchors.centerIn: parent
                    text: button.modelData.icon
                    color: button.modelData.active ? Theme.bg : Theme.fgFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: 21
                    font.weight: Font.Black
                    opacity: button.modelData.active ? 1 : (mouse.containsMouse ? 0.65 : 1)
                }

                // `#workspaces button { border-right: 1px solid @border-color }`
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: parent.height
                    color: Theme.bgEdge
                    visible: button.index < root.rows.length - 1
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    hoverEnabled: true
                    // Hyprland 0.55 config is Lua, and so are its dispatchers:
                    // the old `dispatch workspace N` is a syntax error now.
                    onClicked: Hyprland.dispatch("hl.dsp.focus({workspace = " + button.modelData.id + ", on_current_monitor = true})")
                }
            }
        }
    }
}
