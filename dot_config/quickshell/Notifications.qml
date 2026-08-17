pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon state: history for the control center, a shorter list of
// popups, and do-not-disturb. Entries are plain JS objects so the arrival time
// can ride along with the Notification object.
Singleton {
    id: root

    property bool dnd: false
    property var history: []
    property var popups: []

    readonly property int count: history.length

    // Popup lifetime in ms, 0 meaning "stays until dismissed". expireTimeout is
    // the raw spec value: -1 asks for the server default, 0 asks for persistent.
    function timeoutFor(notification) {
        if (notification.urgency === NotificationUrgency.Critical)
            return 0;
        if (notification.expireTimeout >= 0)
            return notification.expireTimeout;
        return notification.urgency === NotificationUrgency.Low ? 5000 : 10000;
    }

    function dismiss(entry) {
        entry.notification.dismiss();
    }

    // Drops the popup but keeps the entry in history, like swaync does when a
    // popup times out. Entries are matched by id, never by identity: they
    // round-trip through `property var` models as copies, so `===` does not hold.
    function dropPopup(entry) {
        root.popups = root.popups.filter(e => e.id !== entry.id);
    }

    function clearAll() {
        // dismiss() mutates history through the closed handler, so copy first.
        const entries = root.history.slice();
        for (const entry of entries)
            entry.notification.dismiss();
    }

    function toggleDnd() {
        root.dnd = !root.dnd;
        if (root.dnd)
            root.popups = [];
        return root.dnd;
    }

    // Waybar's custom/notification module re-runs its script on RTMIN+8.
    function signalWaybar() {
        Quickshell.execDetached(["pkill", "-RTMIN+8", "waybar"]);
    }

    onCountChanged: root.signalWaybar()
    onDndChanged: root.signalWaybar()

    // waybar's module runs once and waits for signals, so prime it at startup
    // in case waybar came up first.
    Timer {
        running: true
        interval: 100
        onTriggered: root.signalWaybar()
    }

    NotificationServer {
        id: server

        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true
        inlineReplySupported: false

        onNotification: notification => {
            notification.tracked = true;

            // Absolute deadline rather than a delegate-side countdown: the popup
            // list is a plain array, so any change recreates every delegate and
            // would otherwise restart their timers.
            const timeout = root.timeoutFor(notification);

            const entry = {
                id: notification.id,
                notification: notification,
                time: new Date(),
                expiresAt: timeout > 0 ? Date.now() + timeout : 0
            };

            notification.closed.connect(() => {
                root.history = root.history.filter(e => e.id !== entry.id);
                root.dropPopup(entry);
            });

            root.history = [entry, ...root.history];
            if (!root.dnd)
                root.popups = [entry, ...root.popups];
        }
    }
}
