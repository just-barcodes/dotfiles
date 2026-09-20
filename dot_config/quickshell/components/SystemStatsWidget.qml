import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs

// CPU and memory block at the top of the control centre. Replaces the cpu and
// memory bar chips; clicking it focuses the btop workspace as they did.
//
// An Item wrapping the layout, so the click area is a sibling of the layout
// rather than one of its managed children (anchors on those are undefined).
Item {
    id: root

    signal activated

    readonly property bool memoryWarn: SystemStats.memoryUsage > SystemStats.memoryWarnPercent
    readonly property real memoryUsedGib: (SystemStats.memoryTotalKb - SystemStats.memoryAvailableKb) / 1048576
    readonly property real memoryTotalGib: SystemStats.memoryTotalKb / 1048576
    readonly property real swapUsedGib: (SystemStats.swapTotalKb - SystemStats.swapFreeKb) / 1048576
    readonly property real swapTotalGib: SystemStats.swapTotalKb / 1048576

    implicitHeight: column.implicitHeight

    component StatRow: ColumnLayout {
        id: row

        property string icon: ""
        property string label: ""
        property string value: ""
        property string detail: ""
        property real fraction: 0
        property color fillColor: Theme.accent

        Layout.fillWidth: true
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.padding

            Text {
                Layout.minimumWidth: 28
                text: row.icon
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeIcon
            }

            Text {
                text: row.label
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: row.value
                color: row.fillColor === Theme.red ? Theme.red : Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }

        Meter {
            Layout.fillWidth: true
            value: row.fraction
            fillColor: row.fillColor
        }

        Text {
            Layout.fillWidth: true
            visible: row.detail !== ""
            text: row.detail
            color: Theme.fgFaint
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    ColumnLayout {
        id: column

        anchors.fill: parent
        spacing: Theme.padding

        StatRow {
            icon: "\u{f061a}"
            label: "CPU"
            value: SystemStats.cpuUsage < 0 ? "" : SystemStats.cpuUsage + "%"
            fraction: Math.max(0, SystemStats.cpuUsage) / 100
            detail: "load " + SystemStats.loadAverage + "   " + Math.round(SystemStats.temperature) + "\u{b0}C"
        }

        StatRow {
            icon: "\u{f0c9}"
            label: "Memory"
            value: root.memoryUsedGib.toFixed(1) + " / " + root.memoryTotalGib.toFixed(1) + " GiB (" + SystemStats.memoryUsage + "%)"
            fraction: SystemStats.memoryUsage / 100
            fillColor: root.memoryWarn ? Theme.red : Theme.accent
            detail: root.swapUsedGib >= 0.05 ? "swap " + root.swapUsedGib.toFixed(1) + " / " + root.swapTotalGib.toFixed(1) + " GiB" : ""
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            Hyprland.dispatch("hl.dsp.focus({workspace = 99, on_current_monitor = true})");
            root.activated();
        }
    }
}
