import Quickshell
import Quickshell.Io
import qs

ShellRoot {
    NotificationPopups {}

    ControlCenter {
        id: controlCenter
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
}
