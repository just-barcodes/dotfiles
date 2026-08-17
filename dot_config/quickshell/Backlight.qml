pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Backlight via sysfs + brightnessctl. `available` is false on machines without
// the device, which is what swaync's `device: intel_backlight` amounted to.
Singleton {
    id: root

    readonly property string device: "/sys/class/backlight/intel_backlight"
    readonly property int minPercent: 5  // swayosd's min_brightness

    readonly property int max: parseInt(maxFile.text()) || 0
    readonly property int current: parseInt(currentFile.text()) || 0
    readonly property bool available: max > 0
    readonly property int percent: available ? Math.round(current / max * 100) : 0

    function setPercent(target) {
        const clamped = Math.max(root.minPercent, Math.min(100, Math.round(target)));
        Quickshell.execDetached(["brightnessctl", "set", `${clamped}%`]);
    }

    FileView {
        id: maxFile
        path: `${root.device}/max_brightness`
    }

    // sysfs does emit inotify events for this attribute, so the value stays in
    // sync with changes made outside the shell.
    FileView {
        id: currentFile
        path: `${root.device}/brightness`
        watchChanges: true
        onFileChanged: reload()
    }
}
