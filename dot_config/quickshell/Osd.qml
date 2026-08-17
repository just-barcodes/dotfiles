import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs

// Volume / mic / brightness OSD, replacing swayosd. Driven over IPC from the
// multimedia keybinds and the waybar audio module.
//   qs ipc call osd volumeUp
PanelWindow {
    id: root

    readonly property int step: 5  // swayosd's default step

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode mic: Pipewire.defaultAudioSource

    property string icon: ""
    property real value: 0
    property bool dimmed: false

    function showOsd(icon, value, dimmed) {
        root.icon = icon;
        root.value = value;
        root.dimmed = dimmed;
        root.visible = true;
        hideTimer.restart();
    }

    function showSink() {
        const audio = root.sink?.audio;
        if (audio)
            root.showOsd(audio.muted ? "󰸈" : "󰕾", audio.volume, audio.muted);
    }

    function volumeStep(direction) {
        const audio = root.sink?.audio;
        if (!audio)
            return;
        // Snap to the step grid first so repeated presses land on round numbers.
        const percent = Math.round(audio.volume * 100 / root.step) * root.step + direction * root.step;
        audio.volume = Math.max(0, Math.min(1, percent / 100));
        root.showSink();
    }

    function toggleMute() {
        const audio = root.sink?.audio;
        if (!audio)
            return;
        audio.muted = !audio.muted;
        root.showSink();
    }

    function toggleMicMute() {
        const audio = root.mic?.audio;
        if (!audio)
            return;
        audio.muted = !audio.muted;
        root.showOsd(audio.muted ? "󰍭" : "󰍬", audio.volume, audio.muted);
    }

    function brightnessStep(direction) {
        if (!Backlight.available)
            return;
        const percent = Math.max(Backlight.minPercent, Math.min(100, Backlight.percent + direction * root.step));
        Backlight.setPercent(percent);
        root.showOsd("󰃟", percent / 100, false);
    }

    // Volume writes only land once the nodes are bound.
    PwObjectTracker {
        objects: [root.sink, root.mic]
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: false

    anchors {
        bottom: true
    }

    // Roughly swayosd's top_margin of 0.85. Unanchored horizontally, so
    // layer-shell centres it.
    margins {
        bottom: Math.round((root.screen?.height ?? 1080) * 0.12)
    }

    implicitWidth: 320
    implicitHeight: 56
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay

    // Purely informational; never takes clicks.
    mask: Region {}

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2  // swayosd's pill
        color: Theme.bgPopup
        border.width: 1
        border.color: Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.margin
            anchors.rightMargin: Theme.margin
            spacing: Theme.padding

            Text {
                Layout.minimumWidth: 24
                text: root.icon
                color: root.dimmed ? Theme.fgFaint : Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeIcon
            }

            // Same trough and fill as HSlider, without the handle or mouse area.
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 999
                color: Theme.trough

                Rectangle {
                    width: parent.width * root.value
                    height: parent.height
                    radius: 999
                    color: root.dimmed ? Theme.fgFaint : Theme.accent
                }
            }

            Text {
                Layout.minimumWidth: 40
                horizontalAlignment: Text.AlignRight
                text: Math.round(root.value * 100) + "%"
                color: root.dimmed ? Theme.fgFaint : Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
