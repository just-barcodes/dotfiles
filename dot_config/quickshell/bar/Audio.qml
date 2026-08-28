import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

// waybar `pulseaudio`. Click actions go straight to the OSD object rather than
// back out through `qs ipc call osd ...` the way the waybar module has to.
BarChip {
    id: root

    // Set by Bar.qml; the OSD owns the volume/mute steps.
    property var osd: null

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinkAudio: root.sink ? root.sink.audio : null
    readonly property var sourceAudio: root.source ? root.source.audio : null

    readonly property int sinkVolume: root.sinkAudio ? Math.round(root.sinkAudio.volume * 100) : 0
    readonly property int sourceVolume: root.sourceAudio ? Math.round(root.sourceAudio.volume * 100) : 0
    readonly property bool sinkMuted: root.sinkAudio ? root.sinkAudio.muted : false
    readonly property bool sourceMuted: root.sourceAudio ? root.sourceAudio.muted : false

    // format-source / format-source-muted
    readonly property string sourceText: root.sourceMuted ? "\u{f131} " : "\u{f130} " + root.sourceVolume + "%"

    text: {
        if (root.sinkMuted)
            // waybar's format-muted has no space before format_source, unlike
            // the unmuted format below.
            return "\u{f026} muted" + root.sourceText;
        const icon = root.sinkVolume > 50 ? "\u{f028}" : "\u{f027}";
        return icon + " " + String(root.sinkVolume).padStart(3, " ") + "% " + root.sourceText;
    }
    textColor: root.sinkMuted ? Theme.fgFaint : Theme.fg

    onLeftClicked: Quickshell.execDetached(["ghostty", "--class=com.tui.centered", "-e", "pulsemixer"])
    onMiddleClicked: root.osd?.toggleMute()
    onRightClicked: root.osd?.toggleMicMute()
    onScrolled: steps => root.osd?.volumeStep(steps)

    // Per the OSD's own tracker: PwObjectTracker binds per consumer, so this
    // module needs its own or the volume goes stale when the OSD is idle.
    PwObjectTracker {
        objects: [root.sink, root.source].filter(o => o !== null)
    }
}
