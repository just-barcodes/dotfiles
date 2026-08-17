import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs

Rectangle {
    id: root

    required property var entry
    readonly property var notif: entry.notification
    readonly property bool critical: notif.urgency === NotificationUrgency.Critical
    readonly property bool low: notif.urgency === NotificationUrgency.Low

    // The "default" action fires on a body click; the rest become buttons.
    readonly property var defaultAction: notif.actions.find(a => a.identifier === "default") ?? null
    readonly property var buttonActions: notif.actions.filter(a => a.identifier !== "default")

    // An icon-name hint (what `notify-send -i` sends) arrives as image://icon/<name>,
    // and the icon provider renders a placeholder instead of failing when the name
    // isn't in the theme — so names get re-checked and dropped if unresolvable.
    readonly property string thumbnail: {
        const candidate = notif.image !== "" ? notif.image : notif.appIcon;
        if (candidate === "")
            return "";

        const iconPrefix = "image://icon/";
        if (candidate.startsWith(iconPrefix))
            return Quickshell.iconPath(candidate.slice(iconPrefix.length), true);

        return /^(\/|file:|https?:|data:)/.test(candidate) ? candidate : Quickshell.iconPath(candidate, true);
    }

    signal dismissed
    signal actionInvoked

    implicitHeight: layout.implicitHeight + 2 * Theme.margin
    radius: Theme.radius
    color: Theme.bgPopup
    border.width: 2
    border.color: critical ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.5) : low ? Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.3) : Theme.border

    MouseArea {
        anchors.fill: parent
        enabled: root.defaultAction !== null
        onClicked: {
            root.defaultAction.invoke();
            root.actionInvoked();
        }
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.margin
        spacing: Theme.padding

        // Notification image if the app sent one, otherwise its icon. Hidden
        // when the source fails to resolve rather than showing a broken image.
        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 48
            implicitHeight: 48
            radius: Theme.radiusSmall
            color: "transparent"
            visible: root.thumbnail !== "" && thumbnailImage.status === Image.Ready

            Image {
                id: thumbnailImage
                anchors.fill: parent
                source: root.thumbnail
                sourceSize.width: 48
                sourceSize.height: 48
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.padding

                Text {
                    Layout.fillWidth: true
                    text: root.notif.summary
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    text: Qt.formatDateTime(root.entry.time, "HH:mm")
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.5)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }

                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: Theme.radiusSmall
                    color: closeArea.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.3) : Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: Theme.red
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.dismissed()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notif.body
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                textFormat: Text.RichText
                wrapMode: Text.Wrap
                onLinkActivated: link => Quickshell.execDetached(["xdg-open", link])
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: root.buttonActions.length > 0
                spacing: 8

                Repeater {
                    model: root.buttonActions

                    Rectangle {
                        id: actionButton
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: Theme.radiusSmall
                        color: actionArea.containsMouse ? Theme.surfaceHover : Theme.surface

                        Text {
                            anchors.centerIn: parent
                            text: actionButton.modelData.text
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: actionArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                actionButton.modelData.invoke();
                                root.actionInvoked();
                            }
                        }
                    }
                }
            }
        }
    }
}
