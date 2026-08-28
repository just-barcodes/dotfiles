import QtQuick
import Quickshell
import Quickshell.Io
import qs

// waybar `clock`. Minutes precision, so a locked or idle session does not take
// a wakeup per second just to redraw the same string.
BarChip {
    text: Qt.formatDateTime(clock.date, "HH:mm")
    textColor: Theme.accent

    onLeftClicked: Quickshell.execDetached(["ghostty", "--class=com.tui.centered", "--font-size=18", "-e", "calendar.sh"])

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }
}
