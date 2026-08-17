import QtQuick
import QtQuick.Layouts
import qs

// Backlight slider. State and the brightnessctl call live in the Backlight
// singleton, which the OSD shares.
RowLayout {
    visible: Backlight.available
    spacing: Theme.padding

    Text {
        Layout.minimumWidth: 28
        text: "󰃟"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeIcon
    }

    HSlider {
        Layout.fillWidth: true
        value: Backlight.available ? Backlight.current / Backlight.max : 0
        onMoved: value => Backlight.setPercent(value * 100)
    }

    Text {
        Layout.minimumWidth: 40
        horizontalAlignment: Text.AlignRight
        text: Backlight.percent + "%"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }
}
