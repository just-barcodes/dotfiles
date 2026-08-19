import Quickshell
import Quickshell.Io
import qs

ShellRoot {
    NotificationPopups {}

    ControlCenter {
        id: controlCenter
    }

    Osd {
        id: osd
    }

    NetworkPanel {
        id: networkPanel
    }

    Lock {
        id: sessionLock
    }

    // Driven from hyprland keybindings and the waybar module.
    //   qs ipc call notifs toggle
    IpcHandler {
        target: "notifs"

        function toggle(): void {
            controlCenter.toggle();
        }

        function open(): void {
            controlCenter.shown = true;
        }

        function close(): void {
            controlCenter.shown = false;
        }

        function toggleDnd(): bool {
            return Notifications.toggleDnd();
        }

        function clear(): void {
            Notifications.clearAll();
        }

        // Waybar custom/notification module payload, same shape as `swaync-client -swb`.
        function status(): string {
            const count = Notifications.count;
            const alt = (Notifications.dnd ? "dnd-" : "") + (count > 0 ? "notification" : "none");

            return JSON.stringify({
                text: `${count}`,
                alt: alt,
                class: alt,
                tooltip: `${count} notification${count === 1 ? "" : "s"}${Notifications.dnd ? " (do not disturb)" : ""}`
            });
        }
    }

    // Multimedia keys and the waybar audio module, replacing swayosd-client.
    //   qs ipc call osd volumeUp
    IpcHandler {
        target: "osd"

        function volumeUp(): void {
            osd.volumeStep(1);
        }

        function volumeDown(): void {
            osd.volumeStep(-1);
        }

        function volumeMute(): void {
            osd.toggleMute();
        }

        function micMute(): void {
            osd.toggleMicMute();
        }

        function brightnessUp(): void {
            osd.brightnessStep(1);
        }

        function brightnessDown(): void {
            osd.brightnessStep(-1);
        }
    }

    // Waybar's network module, replacing the click-out to wifitui.
    //   qs ipc call network toggle
    IpcHandler {
        target: "network"

        function toggle(): void {
            networkPanel.toggle();
        }

        function open(): void {
            networkPanel.shown = true;
        }

        function close(): void {
            networkPanel.shown = false;
        }
    }

    // hypridle's lock_cmd and before_sleep_cmd, and the CTRL+ALT+DELETE bind,
    // replacing hyprlock. Locking is idempotent, so the old
    // `pidof hyprlock || hyprlock` guard is no longer needed.
    //   qs ipc call lock lock
    IpcHandler {
        target: "lock"

        function lock(): void {
            sessionLock.lock();
        }
    }
}
