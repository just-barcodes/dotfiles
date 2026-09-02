pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Palette is read from ~/.config/theme/palettes/<name>.env, selected by the
// theme name in ~/.local/state/theme. Both files are written by `theme-switch`.
// See THEME-SWITCHING.md.
//
// The *state file* is watched, not the palette: FileView's inotify watch sits
// on the resolved path, so repointing a symlink would never fire it.
// theme-switch rewrites the state file in place, which does.
//
// Property names are unchanged from the hardcoded Selenized Dark version this
// replaces, so nothing else under dot_config/quickshell/ needed touching.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string themeName: (stateFile.text() || "").trim() || "selenized-dark"

    // `key=value` per line, `#` comments. Deliberately not JSON: the same file
    // is sourced by theme-switch and parsed by hypr/style.lua, and only one of
    // the three has a JSON parser.
    readonly property var palette: {
        const out = {};
        for (const line of (paletteFile.text() || "").split("\n")) {
            const entry = line.trim();
            if (entry === "" || entry.startsWith("#"))
                continue;
            const eq = entry.indexOf("=");
            if (eq > 0)
                out[entry.slice(0, eq)] = entry.slice(eq + 1).trim().replace(/^"(.*)"$/, "$1");
        }
        return out;
    }

    // Fallbacks are the Selenized Dark literals this file used to hardcode, so
    // an unreadable palette leaves the shell looking exactly as it did before.
    function p(key: string, fallback: string): string {
        return root.palette[key] ?? fallback;
    }

    function withAlpha(spec: string, a: real): color {
        const c = Qt.color(spec);
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // blockLoading: these are sub-kilobyte local files, and a synchronous read
    // avoids a frame of dark palette when switching to light.
    FileView {
        id: stateFile

        path: `${root.home}/.local/state/theme`
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: paletteFile

        path: `${root.home}/.config/theme/palettes/${root.themeName}.env`
        blockLoading: true
        printErrors: false
    }

    readonly property color bg: p("bg_0", "#103c48")
    readonly property color bgPopup: withAlpha(p("bg_0", "#103c48"), 0.95)
    readonly property color surface: withAlpha(p("blue", "#4695f7"), 0.15)
    readonly property color surfaceHover: withAlpha(p("blue", "#4695f7"), 0.25)
    readonly property color control: withAlpha(p("bg_2", "#2d5b69"), 0.5)
    readonly property color trough: withAlpha(p("bg_2", "#2d5b69"), 0.6)
    readonly property color border: withAlpha(p("blue", "#4695f7"), 0.3)
    readonly property color bgEdge: p("bg_2", "#2d5b69")

    readonly property color accent: p("blue", "#4695f7")
    readonly property color red: p("red", "#fa5750")
    readonly property color green: p("green", "#75b938")
    readonly property color yellow: p("yellow", "#dbb32d")
    readonly property color peach: p("orange", "#ed8649")
    readonly property color sapphire: p("cyan", "#41c7b9")

    readonly property color fg: p("fg_1", "#cad8d9")
    readonly property color fgDim: p("fg_0", "#adbcbc")
    readonly property color fgFaint: p("dim_0", "#72898f")

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 14
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeLarge: 16
    readonly property int fontSizeIcon: 18

    // Bar metrics, carried over from waybar/style.css. barHeight + barMarginTop
    // is the 45px exclusive zone waybar reserved.
    readonly property color barBg: withAlpha(p("bg_dim", "#0d3138"), 0.78)
    readonly property color chipBg: p("bg_0", "#103c48")
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
