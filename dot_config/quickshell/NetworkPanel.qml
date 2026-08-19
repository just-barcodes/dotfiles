import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Networking
import qs
import qs.components

// Wi-Fi and Bluetooth popup, opened from the waybar network module. Replaces
// the click-out to the wifitui TUI, which stays on right-click for enterprise
// networks; bluetuith remains reachable from tui-launcher.
//   qs ipc call network toggle
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
    property var wifiRows: []

    readonly property var netDevices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: root.netDevices.find(d => d.type === DeviceType.Wifi) ?? null

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

    function refreshWifi() {
        const networks = root.wifiDevice?.networks?.values ?? [];

        root.wifiRows = networks.filter(n => n.name).map(n => ({
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

    function runWifi(ssid, action) {
        const network = root.networkForSsid(ssid);
        if (!network)
            return;
        root.busySsid = ssid;
        root.failureSsid = "";
        wifiBusyTimeout.restart();
        action(network);
    }

    function activateWifi(row) {
        if (row.connected)
            root.runWifi(row.ssid, n => n.disconnect());
        else if (row.known || !row.secured)
            root.runWifi(row.ssid, n => n.connect());
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
        root.runWifi(ssid, n => n.connectWithPsk(psk));
    }

    // scannerEnabled is a plain flag on the shared WifiDevice with no reference
    // counting, so track the device it was turned on for and release that exact
    // one. The device object is replaced when the radio is toggled.
    property var scannerDevice: null

    function setWifiScanning(enabled) {
        const next = enabled ? root.wifiDevice : null;

        if (root.scannerDevice && root.scannerDevice !== next)
            root.scannerDevice.scannerEnabled = false;

        root.scannerDevice = next;

        if (root.scannerDevice)
            root.scannerDevice.scannerEnabled = enabled;
    }

    readonly property var adapter: Bluetooth.defaultAdapter

    // Same plain-data rule as wifiRows: BlueZ drops a discovered device from the
    // model as soon as it stops advertising, and a delegate still holding the
    // destroyed object goes down with it.
    property var btRows: []
    property string btBusyAddress: ""

    function deviceForAddress(address) {
        return (root.adapter?.devices?.values ?? []).find(d => d.address === address) ?? null;
    }

    function refreshBt() {
        const devices = root.adapter?.devices?.values ?? [];

        root.btRows = devices.filter(d => d.deviceName).map(d => ({
                    address: d.address,
                    name: d.deviceName,
                    glyph: root.btGlyph(d.icon),
                    connected: d.connected,
                    // bonded is the persisted pairing; paired can drop to false
                    // for a bonded device that is currently out of range.
                    paired: d.paired || d.bonded,
                    // BlueZ reports pairing and connecting separately, and both
                    // read as "working on it" in the row.
                    working: d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting,
                    battery: d.batteryAvailable ? Math.round(d.battery * 100) : -1
                })).sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.paired !== b.paired)
                return a.paired ? -1 : 1;
            return a.name.localeCompare(b.name);
        });
    }

    // device.icon is a freedesktop icon name; this panel is glyph-based, so map
    // the handful BlueZ actually emits and fall back to a generic radio.
    function btGlyph(icon) {
        return ({
                "audio-headset": "󰋎",
                "audio-headphones": "󰋋",
                "audio-card": "󰓃",
                "audio-speakers": "󰓃",
                "input-mouse": "󰍽",
                "input-keyboard": "󰌌",
                "input-gaming": "󰊴",
                "input-tablet": "󰓶",
                "phone": "󰄜",
                "computer": "󰟀",
                "printer": "󰐪",
                "camera-photo": "󰄀",
                "camera-video": "󰕧"
            })[icon] ?? "󰂯";
    }

    function runBt(address, action) {
        const device = root.deviceForAddress(address);
        if (!device)
            return;
        root.btBusyAddress = address;
        btBusyTimeout.restart();
        action(device);
        root.refreshBt();
    }

    function activateBt(row) {
        if (row.connected)
            root.runBt(row.address, d => d.disconnect());
        else if (row.paired)
            root.runBt(row.address, d => d.connect());
        else
            // BlueZ connects most peripherals as part of establishing the bond.
            root.runBt(row.address, d => d.pair());
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
        root.setWifiScanning(root.shown);

        if (root.shown) {
            // Adopt a session left running by an instance that could not finish
            // its own stop, so this close settles it either way.
            if (root.adapter?.discovering)
                root.owesDiscoveryStop = true;
            root.refreshWifi();
            root.refreshBt();
        } else {
            root.passwordSsid = "";
            root.passwordText = "";
            root.failureSsid = "";
        }
    }

    Component.onDestruction: {
        root.setWifiScanning(false);
        if (root.owesDiscoveryStop && root.adapter?.discovering)
            root.adapter.discovering = false;
    }

    // BlueZ holds the discovery session against quickshell's D-Bus connection,
    // so closing the panel does not end it: without an explicit stop the radio
    // stays in inquiry until the shell restarts, which starves A2DP on the same
    // controller into stutters.
    property bool owesDiscoveryStop: false

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.shown && root.adapter !== null && root.adapter.enabled && !root.adapter.discovering
        onTriggered: {
            root.owesDiscoveryStop = true;
            root.adapter.discovering = true;
        }
    }

    // The stop is a timer bound to the confirmed state rather than a write at
    // close time: quickshell only forwards a `discovering` write that differs
    // from the last state BlueZ reported, so a stop issued while a just-fired
    // StartDiscovery is still awaiting confirmation would be swallowed and leak
    // the session. Binding to adapter.discovering means a confirmation landing
    // at any point after close re-arms the stop.
    Timer {
        property int attempts: 0

        interval: 1000
        repeat: true
        running: !root.shown && root.owesDiscoveryStop && root.adapter !== null && root.adapter.discovering
        onRunningChanged: if (running) attempts = 0
        onTriggered: {
            // Bounded so a session another BlueZ client is holding up cannot
            // draw StopDiscovery fire forever.
            attempts += 1;
            if (attempts > 3)
                root.owesDiscoveryStop = false;
            else
                root.adapter.discovering = false;
        }
    }

    // Settled the moment BlueZ reports discovery down, however that happened, so
    // a stale claim never stops a scan another client starts later.
    Connections {
        target: root.adapter
        function onDiscoveringChanged() {
            if (!root.adapter.discovering)
                root.owesDiscoveryStop = false;
        }
    }

    // BlueZ can leave a pair or connect request hanging without reporting a
    // failure, which would strand the row on "Working…". This is the backstop;
    // pendingBt below clears the row as soon as the device actually settles.
    Timer {
        id: btBusyTimeout
        interval: 20000
        onTriggered: {
            root.btBusyAddress = "";
            root.refreshBt();
        }
    }

    Connections {
        id: pendingBt
        target: root.btBusyAddress ? root.deviceForAddress(root.btBusyAddress) : null

        function settle() {
            const device = pendingBt.target;
            if (device.pairing)
                return;
            if (device.state !== BluetoothDeviceState.Connected && device.state !== BluetoothDeviceState.Disconnected)
                return;

            root.btBusyAddress = "";
            btBusyTimeout.stop();
            root.refreshBt();
        }

        function onStateChanged() {
            pendingBt.settle();
        }

        // A device that bonds without connecting settles on this instead.
        function onPairingChanged() {
            pendingBt.settle();
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: {
            root.shown = false;
            root.dismissedAt = Date.now();
        }
    }

    // Rebuilding the rows on a timer covers AP churn, signal drift, and BlueZ
    // device state; per-object property changes never retrigger the `values`
    // bindings. Paused during password entry so the rebuild can't drop the field
    // the user is typing into.
    Timer {
        running: root.shown && root.passwordSsid === ""
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.refreshWifi();
            root.refreshBt();
        }
    }

    // NetworkManager can leave a request hanging without ever reporting a
    // failure, which would strand the row on "Connecting…".
    Timer {
        id: wifiBusyTimeout
        interval: 20000
        onTriggered: root.busySsid = ""
    }

    Connections {
        id: pendingWifi
        target: root.busySsid ? root.networkForSsid(root.busySsid) : null

        function onConnectionFailed(reason) {
            const ssid = root.busySsid;
            root.busySsid = "";
            wifiBusyTimeout.stop();

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
            if (!pendingWifi.target.stateChanging) {
                root.busySsid = "";
                wifiBusyTimeout.stop();
                root.refreshWifi();
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

                Toggle {
                    checked: Networking.wifiEnabled
                    interactive: Networking.wifiHardwareEnabled
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: !Networking.wifiHardwareEnabled || !Networking.wifiEnabled || root.wifiRows.length === 0
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
                Layout.preferredHeight: Math.min(wifiList.implicitHeight, 240)
                visible: root.wifiRows.length > 0 && Networking.wifiEnabled
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    id: wifiList
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.wifiRows

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
                                            onClicked: root.runWifi(item.modelData.ssid, n => n.forget())
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
                                onClicked: root.activateWifi(item.modelData)
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.border
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.padding

                Text {
                    text: root.adapter?.enabled ? "󰂯" : "󰂲"
                    color: root.adapter?.enabled ? Theme.fg : Theme.fgFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeIcon
                }

                Text {
                    Layout.fillWidth: true
                    text: "Bluetooth"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                }

                Toggle {
                    checked: root.adapter?.enabled ?? false
                    interactive: root.adapter !== null
                    onToggled: root.adapter.enabled = !root.adapter.enabled
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: !root.adapter || !root.adapter.enabled || root.btRows.length === 0
                text: {
                    if (!root.adapter)
                        return "No Bluetooth adapter";
                    if (!root.adapter.enabled)
                        return "Bluetooth is off";
                    return "Scanning…";
                }
                color: Theme.fgFaint
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                topPadding: Theme.padding
                bottomPadding: Theme.padding
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(btList.implicitHeight, 200)
                visible: root.btRows.length > 0 && (root.adapter?.enabled ?? false)
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    id: btList
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.btRows

                        delegate: Rectangle {
                            id: btItem

                            required property var modelData

                            readonly property bool busy: root.btBusyAddress === btItem.modelData.address || btItem.modelData.working

                            Layout.fillWidth: true
                            implicitHeight: btRowContent.implicitHeight + 2 * 8
                            radius: Theme.radiusSmall
                            color: btRowArea.containsMouse ? Theme.surfaceHover : "transparent"

                            RowLayout {
                                id: btRowContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 10

                                Text {
                                    text: btItem.modelData.glyph
                                    color: btItem.modelData.connected ? Theme.accent : Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeIcon
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: btItem.modelData.name
                                        color: btItem.modelData.connected ? Theme.accent : Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        text: {
                                            if (btItem.busy)
                                                return "Working…";
                                            if (btItem.modelData.connected)
                                                return btItem.modelData.battery >= 0 ? `Connected · ${btItem.modelData.battery}%` : "Connected";
                                            if (btItem.modelData.paired)
                                                return "Paired";
                                            return "";
                                        }
                                        color: Theme.fgFaint
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSmall
                                        elide: Text.ElideRight
                                    }
                                }

                                // Same always-shown treatment as the Wi-Fi row's
                                // forget button, for the same hover reason.
                                Text {
                                    visible: btItem.modelData.paired
                                    text: "󰩹"
                                    color: btForgetArea.containsMouse ? Theme.red : Theme.fgFaint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize

                                    MouseArea {
                                        id: btForgetArea
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        hoverEnabled: true
                                        onClicked: root.runBt(btItem.modelData.address, d => d.forget())
                                    }
                                }
                            }

                            MouseArea {
                                id: btRowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                // Sits under the forget button so it keeps its
                                // own clicks.
                                z: -1
                                onClicked: root.activateBt(btItem.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
