import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs

ColumnLayout {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    // Application playback streams are both isStream and isSink — a stream that
    // accepts audio from its app (media.class Stream/Output/Audio).
    readonly property var streams: Pipewire.nodes.values.filter(node => node.audio && node.isStream && node.isSink)

    spacing: 8

    PwObjectTracker {
        objects: [root.sink, ...root.streams]
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.padding

        Text {
            Layout.minimumWidth: 28
            text: "󰕾"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeIcon
        }

        HSlider {
            Layout.fillWidth: true
            value: root.sink?.audio?.volume ?? 0
            onMoved: value => {
                if (root.sink?.audio)
                    root.sink.audio.volume = value;
            }
        }

        Text {
            Layout.minimumWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Math.round((root.sink?.audio?.volume ?? 0) * 100) + "%"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Rectangle {
            implicitWidth: 32
            implicitHeight: 26
            radius: Theme.radiusSmall
            color: muteArea.containsMouse ? Theme.surfaceHover : Theme.control

            Text {
                anchors.centerIn: parent
                text: root.sink?.audio?.muted ? "󰸈" : "󰕾"
                color: root.sink?.audio?.muted ? Theme.red : Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                id: muteArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (root.sink?.audio)
                        root.sink.audio.muted = !root.sink.audio.muted;
                }
            }
        }
    }

    // Per-app streams, always expanded (swaync's expand-per-app).
    Repeater {
        model: root.streams

        RowLayout {
            id: stream
            required property PwNode modelData

            Layout.fillWidth: true
            Layout.leftMargin: 32
            spacing: 8

            IconImage {
                implicitSize: 20
                source: Quickshell.iconPath(stream.modelData.properties["application.icon-name"] ?? "", true)
            }

            Text {
                Layout.minimumWidth: 90
                text: stream.modelData.properties["application.name"] ?? stream.modelData.description
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
            }

            HSlider {
                Layout.fillWidth: true
                trackHeight: 4
                handleSize: 12
                value: stream.modelData.audio?.volume ?? 0
                onMoved: value => {
                    if (stream.modelData.audio)
                        stream.modelData.audio.volume = value;
                }
            }

            Text {
                Layout.minimumWidth: 40
                horizontalAlignment: Text.AlignRight
                text: Math.round((stream.modelData.audio?.volume ?? 0) * 100) + "%"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }
}
