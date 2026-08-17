import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs

// Whichever player is playing, else the first one. Hides itself when there are
// none, matching swaync's mpris autohide.
RowLayout {
    id: root

    readonly property var players: Mpris.players.values
    readonly property MprisPlayer player: players.find(p => p.isPlaying) ?? players[0] ?? null

    visible: player !== null
    spacing: Theme.padding

    ClippingRectangle {
        implicitWidth: 48
        implicitHeight: 48
        radius: Theme.radiusSmall
        color: "transparent"
        visible: (root.player?.trackArtUrl ?? "") !== ""

        Image {
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: root.player?.trackTitle ?? ""
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: root.player?.trackArtist ?? ""
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideRight
        }
    }

    Repeater {
        model: [
            {
                icon: "󰒮",
                action: "previous"
            },
            {
                icon: "󰐊",
                action: "togglePlaying"
            },
            {
                icon: "󰒭",
                action: "next"
            }
        ]

        Rectangle {
            id: button
            required property var modelData

            readonly property bool actionAvailable: {
                if (!root.player)
                    return false;
                if (modelData.action === "next")
                    return root.player.canGoNext;
                if (modelData.action === "previous")
                    return root.player.canGoPrevious;
                return root.player.canTogglePlaying;
            }

            implicitWidth: 34
            implicitHeight: 30
            radius: Theme.radiusSmall
            opacity: actionAvailable ? 1 : 0.4
            color: buttonArea.containsMouse && actionAvailable ? Theme.surfaceHover : Theme.control

            Text {
                anchors.centerIn: parent
                text: button.modelData.action === "togglePlaying" && root.player?.isPlaying ? "󰏤" : button.modelData.icon
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                id: buttonArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: button.actionAvailable
                onClicked: root.player[button.modelData.action]()
            }
        }
    }
}
