import QtQuick
import qs

// One waybar module: a chip carrying a single line of text, with the metrics
// from `style.css` (`margin: 3px 0; padding: 4px 10px; font-size: 20px`).
// Modules with their own internals — workspaces, the tray — build their own
// container instead of using this.
Rectangle {
    id: root

    property string text: ""
    property color textColor: Theme.fgDim
    // The centre group runs straight on the bar background; everything else
    // sits on a chip a shade lighter.
    property bool filled: true

    signal leftClicked
    signal rightClicked
    signal middleClicked
    signal scrolled(int steps)

    visible: root.text !== ""
    color: root.filled ? Theme.chipBg : "transparent"
    implicitWidth: label.implicitWidth + Theme.barChipPadding * 2
    implicitHeight: Theme.barChipHeight
    opacity: mouse.containsMouse ? 0.85 : 1

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: root.textColor
        font.family: Theme.fontFamily
        font.pixelSize: Theme.barFontSize
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: event => {
            if (event.button === Qt.LeftButton)
                root.leftClicked();
            else if (event.button === Qt.RightButton)
                root.rightClicked();
            else if (event.button === Qt.MiddleButton)
                root.middleClicked();
        }

        onWheel: event => {
            if (event.angleDelta.y !== 0)
                root.scrolled(event.angleDelta.y > 0 ? 1 : -1);
        }
    }
}
