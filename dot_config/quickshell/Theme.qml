pragma Singleton

import QtQuick
import Quickshell

// Selenized dark palette, carried over from the swaync stylesheet it replaces.
Singleton {
    readonly property color bg: "#103c48"
    readonly property color bgPopup: Qt.rgba(16 / 255, 60 / 255, 72 / 255, 0.95)
    readonly property color surface: Qt.rgba(70 / 255, 149 / 255, 247 / 255, 0.15)
    readonly property color surfaceHover: Qt.rgba(70 / 255, 149 / 255, 247 / 255, 0.25)
    readonly property color control: Qt.rgba(45 / 255, 91 / 255, 105 / 255, 0.5)
    readonly property color trough: Qt.rgba(45 / 255, 91 / 255, 105 / 255, 0.6)
    readonly property color border: Qt.rgba(70 / 255, 149 / 255, 247 / 255, 0.3)
    readonly property color bgEdge: "#2d5b69"

    readonly property color accent: "#4695f7"
    readonly property color red: "#fa5750"
    readonly property color green: "#75b938"

    readonly property color fg: "#cad8d9"
    readonly property color fgDim: "#adbcbc"
    readonly property color fgFaint: "#72898f"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 14
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeLarge: 16
    readonly property int fontSizeIcon: 18

    readonly property int radius: 12
    readonly property int radiusSmall: 8
    readonly property int padding: 12
    readonly property int margin: 16
}
