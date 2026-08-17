import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import qs

// Wi-Fi popup, opened from the waybar network module. Replaces the click-out
// to the wifitui TUI, which stays on right-click for enterprise networks.
//   qs ipc call wifi toggle
PanelWindow {
    id: root

    property bool shown: false
    property double dismissedAt: 0

    // Row expanded into password entry, the passphrase typed into it, the SSID
    // with an action in flight, and the last failure. All keyed by SSID rather
    // than held on the delegate: see rows below.
    property string passwordSsid: ""
    property string passwordText: ""
    property string busySsid: ""
    property string failureSsid: ""
    property string failureText: ""

    // Plain-data snapshot of the access points. Handing a live WifiNetwork to a
    // delegate crashes quickshell when NetworkManager drops that AP mid-scan
    // while the delegate is still incubating, so delegates only ever see
    // primitives and actions resolve the object again via networkForSsid().
    property var rows: []

    readonly property var devices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: root.devices.find(d => d.type === DeviceType.Wifi) ?? null

    // Clicking the waybar module while the panel is open clears the focus grab
    // (press) and then runs the toggle (release), which would reopen it. Same
    // dismissal guard as ControlCenter.
    function toggle() {
        if (!root.shown && Date.now() - root.dismissedAt < 300)
            return;
        root.shown = !root.shown;
    }

    function networkForSsid(ssid) {
        return (root.wifiDevice?.networks?.values ?? []).find(n => n.name === ssid) ?? null;
    }

    function refresh() {
        const networks = root.wifiDevice?.networks?.values ?? [];

        root.rows = networks.filter(n => n.name).map(n => ({
                    ssid: n.name,
                    connected: n.connected,
                    known: n.known,
                    signal: Math.round((n.signalStrength ?? 0) * 100),
                    // Owe is opportunistic encryption, which needs no passphrase.
                    secured: n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe,
                    // EAP wants an identity and a method too; hand those to wifitui.
                    enterprise: n.security === WifiSecurityType.Wpa2Eap || n.security === WifiSecurityType.WpaEap
                })).sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.known !== b.known)
                return a.known ? -1 : 1;
            return b.signal - a.signal;
        });
    }

    function run(ssid, action) {
        const network = root.networkForSsid(ssid);
        if (!network)
            return;
        root.busySsid = ssid;
        root.failureSsid = "";
        busyTimeout.restart();
        action(network);
    }

    function activate(row) {
        if (row.connected)
            root.run(row.ssid, n => n.disconnect());
        else if (row.known || !row.secured)
            root.run(row.ssid, n => n.connect());
        else
            root.promptPassword(row.ssid);
    }

    function promptPassword(ssid) {
        root.passwordSsid = ssid;
        root.passwordText = "";
        root.failureSsid = "";
    }

    function submitPassword() {
        const ssid = root.passwordSsid;
        const psk = root.passwordText;
        root.passwordSsid = "";
        root.passwordText = "";
        root.run(ssid, n => n.connectWithPsk(psk));
    }

    // scannerEnabled is a plain flag on the shared WifiDevice with no reference
    // counting, so track the device it was turned on for and release that exact
    // one. The device object is replaced when the radio is toggled.
    property var scannerDevice: null

    function setScanning(enabled) {
        const next = enabled ? root.wifiDevice : null;

        if (root.scannerDevice && root.scannerDevice !== next)
            root.scannerDevice.scannerEnabled = false;

        root.scannerDevice = next;

        if (root.scannerDevice)
            root.scannerDevice.scannerEnabled = enabled;
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: shown

    anchors {
        top: true
        right: true
    }

    margins {
        right: Theme.margin
    }

    implicitWidth: 380
    implicitHeight: content.implicitHeight + 2 * Theme.padding
    exclusiveZone: 0
    color: "transparent"
    focusable: true

    // active is set imperatively: the compositor writes false on dismissal,
    // which would destroy a binding.
    onShownChanged: {
        focusGrab.active = root.shown;
        root.setScanning(root.shown);

        if (root.shown) {
            root.refresh();
        } else {
            root.passwordSsid = "";
            root.passwordText = "";
            root.failureSsid = "";
        }
    }

    Component.onDestruction: root.setScanning(false)

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: {
            root.shown = false;
            root.dismissedAt = Date.now();
        }
    }

    // Rebuilding the rows on a timer covers both AP churn and signal drift; the
    // per-object signalStrength changes never retrigger the `values` binding.
    // Paused during password entry so the rebuild can't drop the field the user
    // is typing into.
    Timer {
        running: root.shown && root.passwordSsid === ""
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // NetworkManager can leave a request hanging without ever reporting a
    // failure, which would strand the row on "Connecting…".
    Timer {
        id: busyTimeout
        interval: 20000
        onTriggered: root.busySsid = ""
    }

    Connections {
        id: pending
        target: root.busySsid ? root.networkForSsid(root.busySsid) : null

        function onConnectionFailed(reason) {
            const ssid = root.busySsid;
            root.busySsid = "";
            busyTimeout.stop();

            // NoSecrets means the saved passphrase was wrong or missing, so drop
            // straight back into password entry instead of making the user
            // reopen the row. promptPassword clears the failure, so set it after.
            if (reason === ConnectionFailReason.NoSecrets) {
                root.promptPassword(ssid);
                root.failureText = "Wrong password";
            } else {
                root.failureText = ConnectionFailReason.toString(reason);
            }

            root.failureSsid = ssid;
        }

        function onStateChangingChanged() {
            if (!pending.target.stateChanging) {
                root.busySsid = "";
                busyTimeout.stop();
                root.refresh();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bgPopup
        border.width: 1
        border.color: Theme.border

        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (root.passwordSsid !== "") {
                    root.passwordSsid = "";
                    root.passwordText = "";
                } else {
                    root.shown = false;
                }
                event.accepted = true;
            }
        }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Theme.padding
            spacing: Theme.padding

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.padding

                Text {
                    text: Networking.wifiEnabled ? "󰤨" : "󰤮"
                    color: Networking.wifiEnabled ? Theme.fg : Theme.fgFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeIcon
                }

                Text {
                    Layout.fillWidth: true
                    text: "Wi-Fi"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                }

                // Same switch as ControlCenter's Do Not Disturb toggle.
                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 24
                    radius: Theme.radiusSmall
                    color: Networking.wifiEnabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5) : Theme.control
                    border.width: 1
                    border.color: Theme.border
                    opacity: Networking.wifiHardwareEnabled ? 1 : 0.4

                    Rectangle {
                        x: Networking.wifiEnabled ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: Theme.radiusSmall
                        color: Theme.accent

                        Behavior on x {
                            NumberAnimation {
                                duration: 100
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: Networking.wifiHardwareEnabled
                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: !Networking.wifiHardwareEnabled || !Networking.wifiEnabled || root.rows.length === 0
                text: {
                    if (!Networking.wifiHardwareEnabled)
                        return "Wi-Fi is blocked in hardware";
                    if (!Networking.wifiEnabled)
                        return "Wi-Fi is off";
                    return "Scanning…";
                }
                color: Theme.fgFaint
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                topPadding: Theme.padding
                bottomPadding: Theme.padding
            }

            // A Repeater rather than a ListView: rows vary in height once one
            // expands for password entry, and a ListView estimates contentHeight
            // from the delegates it has instantiated, which makes a height bound
            // to it oscillate.
            ScrollView {
                Layout.fillWidth: true
                // Caps the popup at roughly eight rows; the rest scrolls.
                Layout.preferredHeight: Math.min(list.implicitHeight, 380)
                visible: root.rows.length > 0 && Networking.wifiEnabled
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    id: list
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.rows

                        delegate: Rectangle {
                            id: item

                            required property var modelData

                            readonly property bool busy: root.busySsid === item.modelData.ssid
                            readonly property bool entering: root.passwordSsid === item.modelData.ssid
                            readonly property bool failed: root.failureSsid === item.modelData.ssid

                            Layout.fillWidth: true
                            implicitHeight: rowContent.implicitHeight + 2 * 8
                            radius: Theme.radiusSmall
                            color: rowArea.containsMouse || item.entering ? Theme.surfaceHover : "transparent"

                            ColumnLayout {
                                id: rowContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Text {
                                        // 0-4 bars, matching the waybar module's glyphs.
                                        text: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor(item.modelData.signal / 25))]
                                        color: item.modelData.connected ? Theme.accent : Theme.fgDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeIcon
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        Text {
                                            Layout.fillWidth: true
                                            text: item.modelData.ssid
                                            color: item.modelData.connected ? Theme.accent : Theme.fg
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            visible: text !== ""
                                            text: {
                                                if (item.busy)
                                                    return "Connecting…";
                                                if (item.failed)
                                                    return root.failureText;
                                                if (item.modelData.connected)
                                                    return "Connected";
                                                if (item.modelData.enterprise)
                                                    return "Enterprise, use wifitui";
                                                if (item.modelData.known)
                                                    return "Saved";
                                                return "";
                                            }
                                            color: item.failed ? Theme.red : Theme.fgFaint
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeSmall
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        visible: item.modelData.secured
                                        text: "󰌾"
                                        color: Theme.fgFaint
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSmall
                                    }

                                    // Forget is the only action that needs its own
                                    // hit target; everything else is the row click.
                                    // Always shown for saved networks: revealing it
                                    // on row hover would hide it the moment the
                                    // pointer reached it and took the hover away.
                                    Text {
                                        visible: item.modelData.known
                                        text: "󰩹"
                                        color: forgetArea.containsMouse ? Theme.red : Theme.fgFaint
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize

                                        MouseArea {
                                            id: forgetArea
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            hoverEnabled: true
                                            onClicked: root.run(item.modelData.ssid, n => n.forget())
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 28
                                    visible: item.entering
                                    spacing: 6

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 30
                                        radius: Theme.radiusSmall
                                        color: Theme.control
                                        border.width: 1
                                        border.color: field.activeFocus ? Theme.accent : Theme.border

                                        TextField {
                                            id: field
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            text: root.passwordText
                                            placeholderText: "Password"
                                            placeholderTextColor: Theme.fgFaint
                                            echoMode: TextInput.Password
                                            color: Theme.fg
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize
                                            background: null
                                            verticalAlignment: TextInput.AlignVCenter

                                            onTextEdited: root.passwordText = text
                                            onAccepted: root.submitPassword()

                                            // This row is built when the prompt
                                            // opens, so the grab runs once per
                                            // prompt rather than on every refresh.
                                            Component.onCompleted: forceActiveFocus()
                                        }
                                    }

                                    Rectangle {
                                        implicitWidth: 64
                                        implicitHeight: 30
                                        radius: Theme.radiusSmall
                                        color: connectArea.containsMouse ? Theme.surfaceHover : Theme.control

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Connect"
                                            color: Theme.fg
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeSmall
                                        }

                                        MouseArea {
                                            id: connectArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: root.submitPassword()
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: rowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                // Sits under the password row and the forget
                                // button so both keep their own clicks.
                                z: -1
                                onClicked: root.activate(item.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
