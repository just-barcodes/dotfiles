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
    readonly property color yellow: "#dbb32d"
    readonly property color peach: "#ed8649"
    readonly property color sapphire: "#41c7b9"

    readonly property color fg: "#cad8d9"
    readonly property color fgDim: "#adbcbc"
    readonly property color fgFaint: "#72898f"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 14
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeLarge: 16
    readonly property int fontSizeIcon: 18

    // Bar metrics, carried over from waybar/style.css. barHeight + barMarginTop
    // is the 45px exclusive zone waybar reserved.
    readonly property color barBg: Qt.rgba(13 / 255, 49 / 255, 56 / 255, 0.78)
    readonly property color chipBg: "#103c48"
    readonly property int barHeight: 43
    readonly property int barMarginTop: 2
    readonly property int barMarginSide: 6
    readonly property int barChipHeight: 37
    readonly property int barChipPadding: 10
    readonly property int barFontSize: 20
    readonly property int barWorkspaceWidth: 40

    readonly property int radius: 12
    readonly property int radiusSmall: 8
    readonly property int padding: 12
    readonly property int margin: 16
}
