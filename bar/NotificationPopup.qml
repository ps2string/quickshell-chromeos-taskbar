import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications
import ".."
import "../services"

PanelWindow {
    id: popupWindow

    anchors {
        top: true
        right: true
    }

    margins {
        top: 16
        right: 16
    }

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    color: "transparent"

    property var popups: []

    visible: popups.length > 0

    implicitWidth: 380
    implicitHeight: popupsColumn.implicitHeight

    Connections {
        target: NotificationService

        function onNotification(notif) {
            if (SystemService.dndActive) return;

            let list = popupWindow.popups.slice();
            list.unshift(notif);

            if (list.length > 4) {
                list = list.slice(0, 4);
            }

            popupWindow.popups = list;
        }
    }

    function removePopup(targetNotif) {
        popupWindow.popups = popupWindow.popups.filter(n => n !== null && n !== targetNotif);
    }

    ColumnLayout {
        id: popupsColumn
        width: parent.width
        spacing: 10

        Repeater {
            model: popupWindow.popups

            delegate: Rectangle {
                id: toastDelegate
                required property var modelData
                property var notif: modelData

                Connections {
                    target: notif
                    ignoreUnknownSignals: true
                    function onClosed(reason) {
                        popupWindow.removePopup(notif);
                    }
                }

                Layout.fillWidth: true
                implicitHeight: toastContent.implicitHeight + 24
                radius: 20
                color: Qt.alpha(ColorService.bgElevated, 0.95)
                border.color: Qt.rgba(1, 1, 1, 0.12)
                border.width: 1

                Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Timer {
                    id: autoDismissTimer
                    interval: (notif && notif.expireTimeout > 0) ? Math.max(2000, notif.expireTimeout * 1000) : 5000
                    running: true
                    repeat: false
                    onTriggered: popupWindow.removePopup(notif)
                }

                ColumnLayout {
                    id: toastContent
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            width: 26; height: 26; radius: 13
                            color: Qt.alpha(ColorService.accent, 0.2)
                            Text {
                                anchors.centerIn: parent
                                text: "󰂚"
                                font.family: Theme.fontIcon
                                font.pixelSize: 13
                                color: ColorService.accent
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: (notif && notif.appName) ? notif.appName : "System"
                            color: ColorService.textPrimary
                            font.family: Theme.fontMain
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: 26; height: 26; radius: 13
                            color: closeArea.containsMouse 
                                ? Qt.alpha(ColorService.accent, 0.25) 
                                : Qt.rgba(1, 1, 1, 0.08)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: Theme.fontIcon
                                font.pixelSize: 14
                                color: closeArea.containsMouse ? ColorService.accent : ColorService.textSecondary
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: closeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (notif && notif.dismiss) notif.dismiss();
                                    popupWindow.removePopup(notif);
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                visible: notif && notif.summary && notif.summary.length > 0
                                text: notif ? notif.summary : ""
                                color: ColorService.textPrimary
                                font.family: Theme.fontMain
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }

                            Text {
                                visible: notif && notif.body && notif.body.length > 0
                                text: notif ? notif.body : ""
                                color: ColorService.textSecondary
                                font.family: Theme.fontMain
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                textFormat: Text.RichText
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }

                        Image {
                            visible: notif && notif.image && notif.image.length > 0
                            source: notif ? notif.image : ""
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            fillMode: Image.PreserveAspectCrop
                            Layout.alignment: Qt.AlignTop
                        }
                    }

                    RowLayout {
                        visible: notif && notif.actions && notif.actions.length > 0
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: (notif && notif.actions) ? notif.actions : []
                            delegate: Rectangle {
                                id: actionBtn
                                property var action: modelData
                                Layout.fillWidth: true
                                height: 32
                                radius: 16
                                color: actionArea.containsMouse ? Qt.alpha(ColorService.accent, 0.3) : Qt.alpha(ColorService.accent, 0.15)
                                border.color: Qt.alpha(ColorService.accent, 0.4)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: actionBtn.action ? actionBtn.action.text : ""
                                    color: ColorService.accent
                                    font.family: Theme.fontMain
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: actionArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (actionBtn.action && actionBtn.action.invoke) {
                                            actionBtn.action.invoke();
                                        }
                                        popupWindow.removePopup(notif);
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        visible: notif && notif.hasInlineReply
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 16
                            color: ColorService.bgBase
                            border.color: ColorService.accent
                            border.width: 1

                            TextInput {
                                id: replyInput
                                anchors.fill: parent
                                anchors.margins: 6
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                font.family: Theme.fontMain
                                font.pixelSize: 12
                                color: ColorService.textPrimary
                                verticalAlignment: Text.AlignVCenter

                                Text {
                                    anchors.fill: parent
                                    visible: replyInput.text.length === 0 && !replyInput.activeFocus
                                    text: notif ? (notif.inlineReplyPlaceholder || "Reply...") : "Reply..."
                                    color: ColorService.textSecondary
                                    font: replyInput.font
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onAccepted: {
                                    if (notif && notif.sendInlineReply && text.length > 0) {
                                        notif.sendInlineReply(text);
                                        popupWindow.removePopup(notif);
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 56; height: 32; radius: 16
                            color: ColorService.accent

                            Text {
                                anchors.centerIn: parent
                                text: "Send"
                                color: ColorService.bgBase
                                font.family: Theme.fontMain
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (notif && notif.sendInlineReply && replyInput.text.length > 0) {
                                        notif.sendInlineReply(replyInput.text);
                                        popupWindow.removePopup(notif);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
