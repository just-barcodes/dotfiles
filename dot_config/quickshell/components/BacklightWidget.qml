import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

// Backlight via sysfs + brightnessctl. Only shows up on machines that have the
// device, which is what swaync's `device: intel_backlight` amounted to.
RowLayout {
    id: root

    readonly property string device: "/sys/class/backlight/intel_backlight"
    readonly property int minPercent: 5

    readonly property int max: parseInt(maxFile.text()) || 0
    readonly property int current: parseInt(currentFile.text()) || 0
    readonly property bool available: max > 0

    visible: available
    spacing: Theme.padding

    FileView {
        id: maxFile
        path: `${root.device}/max_brightness`
    }

    FileView {
        id: currentFile
        path: `${root.device}/brightness`
        watchChanges: true
        onFileChanged: reload()
    }

    Text {
        Layout.minimumWidth: 28
        text: "󰃟"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeIcon
    }

    HSlider {
        Layout.fillWidth: true
        value: root.available ? root.current / root.max : 0
        onMoved: value => {
            const percent = Math.max(root.minPercent, Math.round(value * 100));
            Quickshell.execDetached(["brightnessctl", "set", `${percent}%`]);
        }
    }

    Text {
        Layout.minimumWidth: 40
        horizontalAlignment: Text.AlignRight
        text: (root.available ? Math.round(root.current / root.max * 100) : 0) + "%"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }
}
