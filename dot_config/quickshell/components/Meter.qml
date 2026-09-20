import QtQuick
import qs

// Read-only 0..1 bar: the HSlider track without the handle.
Item {
    id: root

    property real value: 0
    property color fillColor: Theme.accent

    implicitHeight: 6

    Rectangle {
        anchors.fill: parent
        radius: 999
        color: Theme.trough

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: 999
            color: root.fillColor
        }
    }
}
