pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// cpu, memory and temperature for the bar, on one timer and one set of
// FileViews. FileView.reload() works on procfs; watchChanges does not, because
// procfs emits no inotify events, so this polls.
//
// The state lives here rather than on the chips because cpu needs the previous
// /proc/stat sample to compute a delta, which has to outlive any one delegate.
Singleton {
    id: root

    // waybar polled cpu every 10s and memory every 30s. One timer covers all
    // three here, and 5s makes the cpu figure mean something.
    readonly property int interval: 5000

    // (MemTotal - MemAvailable) / MemTotal, which is the figure waybar shows.
    // Deriving "used" from MemFree plus Buffers and Cached instead lands two to
    // four points lower.
    readonly property int memoryUsage: {
        const total = parseInt(meminfo.text().match(/MemTotal:\s+(\d+)/)?.[1]) || 0;
        const available = parseInt(meminfo.text().match(/MemAvailable:\s+(\d+)/)?.[1]) || 0;
        return total > 0 ? Math.round((1 - available / total) * 100) : 0;
    }

    readonly property real temperature: (parseInt(tempFile.text()) || 0) / 1000

    // Filled in from the second sample onwards: the first tick has nothing to
    // difference against, so the chip stays blank for one interval at startup.
    property int cpuUsage: -1

    property real previousIdle: 0
    property real previousTotal: 0

    // idle counts iowait as well as idle, which is what waybar does. Leaving
    // iowait out reads ~60% on this machine where waybar reads ~16%, because
    // its iowait column outgrows its idle column.
    readonly property var cpuSample: {
        const fields = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        if (fields.length < 5)
            return null;
        return {
            idle: fields[3] + fields[4],
            total: fields.reduce((sum, n) => sum + n, 0)
        };
    }

    onCpuSampleChanged: {
        if (!root.cpuSample)
            return;

        const deltaTotal = root.cpuSample.total - root.previousTotal;
        const deltaIdle = root.cpuSample.idle - root.previousIdle;
        const first = root.previousTotal === 0;

        root.previousTotal = root.cpuSample.total;
        root.previousIdle = root.cpuSample.idle;

        if (!first && deltaTotal > 0)
            root.cpuUsage = Math.round((1 - deltaIdle / deltaTotal) * 100);
    }

    FileView {
        id: stat

        path: "/proc/stat"
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
    }

    FileView {
        id: tempFile

        path: root.temperaturePath
    }

    // hwmon indices are assigned in probe order and move between boots, so the
    // sensor is resolved by name once at startup rather than hardcoded. The old
    // waybar `hwmon-path` pointed at hwmon1, which is acpi_fan on this boot and
    // has no temperature attribute at all; waybar had been silently falling
    // back to the thermal zone, which is also the fallback here.
    property string temperaturePath: ""

    Process {
        running: true
        command: ["sh", "-c", "for f in /sys/class/hwmon/*/name; do case \"$(cat \"$f\")\" in coretemp|k10temp) d=${f%/name}; [ -r \"$d/temp1_input\" ] && { echo \"$d/temp1_input\"; exit; };; esac; done; echo /sys/class/thermal/thermal_zone0/temp"]

        stdout: StdioCollector {
            onStreamFinished: root.temperaturePath = this.text.trim()
        }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            stat.reload();
            meminfo.reload();
            if (root.temperaturePath !== "")
                tempFile.reload();
        }
    }
}
