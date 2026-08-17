import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs

// ext-session-lock screen, replacing hyprlock. Locking is driven over IPC by
// hypridle (lock_cmd, before_sleep_cmd) and the CTRL+ALT+DELETE bind:
//   qs ipc call lock lock
//
// There is deliberately no unlock IPC: PAM is the only way out.
Scope {
    id: root

    readonly property bool locked: sessionLock.locked

    property string password: ""
    property bool checking: false
    property bool failed: false

    // Whatever pam_fprintd last said, e.g. "Place your finger on the reader".
    property string fingerprintMessage: ""
    // Fingerprint runs that ended immediately, which is what a host with no
    // reader (or no PAM file) looks like. Retrying those would spin forever.
    property int fingerprintQuickFailures: 0
    property double fingerprintStartedAt: 0

    function lock(): void {
        if (sessionLock.locked)
            return;
        root.password = "";
        root.checking = false;
        root.failed = false;
        root.fingerprintMessage = "";
        root.fingerprintQuickFailures = 0;
        sessionLock.locked = true;
        root.startFingerprint();
    }

    function unlock(): void {
        root.password = "";
        root.checking = false;
        root.failed = false;
        root.fingerprintMessage = "";
        if (fingerprint.active)
            fingerprint.abort();
        sessionLock.locked = false;
    }

    function submit(): void {
        // hyprlock's ignore_empty_input.
        if (root.checking || root.password === "")
            return;
        root.failed = false;
        root.checking = true;
        passwordPam.start();
    }

    function startFingerprint(): void {
        root.fingerprintStartedAt = Date.now();
        fingerprint.start();
    }

    function retryFingerprint(): void {
        if (!sessionLock.locked)
            return;
        if (Date.now() - root.fingerprintStartedAt < 2000) {
            if (++root.fingerprintQuickFailures >= 3) {
                root.fingerprintMessage = "";
                return;
            }
        } else {
            root.fingerprintQuickFailures = 0;
        }
        fingerprintRetry.restart();
    }

    // Password. /etc/pam.d/login is the stack hyprlock's own PAM file included,
    // so this is the same authentication it did.
    PamContext {
        id: passwordPam
        config: "login"

        onPamMessage: {
            if (passwordPam.responseRequired)
                passwordPam.respond(root.password);
        }

        onCompleted: result => {
            root.checking = false;
            if (result === PamResult.Success) {
                root.unlock();
            } else {
                root.password = "";
                root.failed = true;
            }
        }

        onError: error => {
            root.checking = false;
            root.password = "";
            root.failed = true;
            console.warn("lock: password pam error:", PamError.toString(error));
        }
    }

    // Fingerprint needs its own context: one PAM stack cannot offer password
    // and finger in parallel. /etc/pam.d/quickshell-fprint is installed by
    // .chezmoiscripts/run_onchange_install_pam_quickshell_fprint.sh.tmpl, and
    // only on hosts that have pam_fprintd.
    PamContext {
        id: fingerprint
        config: "quickshell-fprint"

        onPamMessage: {
            if (!fingerprint.responseRequired && fingerprint.message !== "")
                root.fingerprintMessage = fingerprint.message;
        }

        onCompleted: result => {
            if (result === PamResult.Success)
                root.unlock();
            else
                root.retryFingerprint();
        }

        onError: error => root.retryFingerprint()
    }

    // hyprlock's retry_delay was 250ms; a second is kinder to fprintd and
    // still faster than anyone can move a finger.
    Timer {
        id: fingerprintRetry
        interval: 1000
        onTriggered: root.startFingerprint()
    }

    SystemClock {
        id: clock
        enabled: sessionLock.locked
        precision: SystemClock.Minutes
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            id: surface

            color: "black"

            Item {
                anchors.fill: parent
                focus: true

                Keys.onPressed: event => {
                    event.accepted = true;
                    if (root.checking)
                        return;

                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.submit();
                    } else if (event.key === Qt.Key_Backspace) {
                        root.password = root.password.slice(0, -1);
                    } else if (event.key === Qt.Key_Escape || (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier))) {
                        root.password = "";
                    } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 0x20 && event.text.charCodeAt(0) !== 0x7f) {
                        root.password += event.text;
                        root.failed = false;
                    }
                }

                // Clock, top right, as in the hyprlock layout.
                Column {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 30
                    anchors.topMargin: 20
                    spacing: 4

                    Text {
                        anchors.right: parent.right
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 90
                    }

                    Text {
                        anchors.right: parent.right
                        text: Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy")
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 25
                    }
                }

                // Input field: hyprlock's 40% x 5%, 5px outline, 15px rounding.
                Rectangle {
                    id: field

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 20

                    width: Math.round(parent.width * 0.4)
                    height: Math.round(parent.height * 0.05)
                    radius: 15
                    color: Theme.bg
                    border.width: 5
                    border.color: root.checking ? Theme.green : root.failed ? Theme.red : Theme.accent

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 2 * Theme.margin
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.checking ? "Verifying..." : root.failed ? "Authentication failed" : root.password === "" ? "Input password..." : "●".repeat(root.password.length)
                        color: root.failed ? Theme.red : root.password === "" ? Theme.fgFaint : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        font.letterSpacing: root.password === "" ? 0 : 4
                    }
                }

                Text {
                    anchors.horizontalCenter: field.horizontalCenter
                    anchors.top: field.bottom
                    anchors.topMargin: Theme.margin

                    visible: root.fingerprintMessage !== ""
                    text: root.fingerprintMessage
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }
}
