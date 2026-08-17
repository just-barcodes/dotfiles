import QtQuick
import qs

// Horizontal 0..1 slider matching the swaync widget sliders.
Item {
    id: root

    property real value: 0
    property int trackHeight: 6
    property int handleSize: 14

    signal moved(real value)

    implicitHeight: handleSize

    function positionToValue(x) {
        return Math.max(0, Math.min(1, x / root.width));
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackHeight
        radius: 999
        color: Theme.trough

        Rectangle {
            width: parent.width * root.value
            height: parent.height
            radius: 999
            color: Theme.accent
        }
    }

    Rectangle {
        x: (root.width - width) * root.value
        anchors.verticalCenter: parent.verticalCenter
        width: root.handleSize
        height: root.handleSize
        radius: 999
        color: Theme.fg
    }

    MouseArea {
        anchors.fill: parent
        onPressed: mouse => root.moved(root.positionToValue(mouse.x))
        onPositionChanged: mouse => {
            if (pressed)
                root.moved(root.positionToValue(mouse.x));
        }
    }
}
