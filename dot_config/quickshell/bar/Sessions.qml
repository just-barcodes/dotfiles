import QtQuick
import Quickshell
import Quickshell.Io
import qs

// waybar `custom/sm`: counts of waiting / running / idle agent sessions.
// Reads `sm status --json` directly instead of going through
// waybar/scripts/sm-status.sh, whose jq pass existed only to build the pango
// markup that waybar needs to colour three numbers in one label.
Rectangle {
    id: root

    property int waiting: 0
    property int running: 0
    property int idle: 0

    color: Theme.chipBg
    implicitWidth: row.implicitWidth + Theme.barChipPadding * 2
    implicitHeight: Theme.barChipHeight
    opacity: mouse.containsMouse ? 0.85 : 1

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: [
                {
                    color: Theme.red,
                    count: root.waiting
                },
                {
                    color: Theme.green,
                    count: root.running
                },
                {
                    color: Theme.yellow,
                    count: root.idle
                }
            ]

            delegate: Row {
                required property var modelData

                spacing: 5

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 10
                    radius: 5
                    color: parent.modelData.color
                }

                Text {
                    text: parent.modelData.count
                    color: parent.modelData.color
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.barFontSize
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        onClicked: Quickshell.execDetached(["sm-switch.sh"])
    }

    Process {
        id: query

        command: ["sm", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                let sessions = [];
                try {
                    sessions = JSON.parse(this.text);
                } catch (e) {
                    return;
                }
                root.waiting = sessions.filter(s => s.Status === "waiting").length;
                root.running = sessions.filter(s => s.Status === "running").length;
                root.idle = sessions.filter(s => s.Status === "idle").length;
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: query.running = true
    }
}
