import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../services"

ScrollView {
    id: root
    anchors.fill: parent
    contentWidth: availableWidth
    clip: true

    ColumnLayout {
        width: root.availableWidth - 16
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20

        Item { height: 4 }

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Rectangle {
                width: 48; height: 48; radius: 24
                color: Qt.alpha(ColorService.accent, SystemService.bluetoothOn ? 0.18 : 0.08)
                Behavior on color { ColorAnimation { duration: 300 } }
                Text {
                    anchors.centerIn: parent
                    text: SystemService.bluetoothOn ? "󰂯" : "󰂲"
                    font.family: Theme.fontIcon
                    font.pixelSize: 22
                    color: SystemService.bluetoothOn ? ColorService.accent : ColorService.textSecondary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    text: "Bluetooth"
                    font.family: Theme.fontMain
                    font.pixelSize: 22
                    font.bold: true
                    color: ColorService.textPrimary
                }
                Text {
                    text: SystemService.bluetoothOn
                        ? (SystemService.isScanningBt ? "Scanning for devices…" : "Active — ready to pair")
                        : "Pair and manage Bluetooth accessories"
                    font.family: Theme.fontMain
                    font.pixelSize: 13
                    color: ColorService.textSecondary
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 68
            radius: 20
            color: ColorService.bgSurface
            border.color: SystemService.bluetoothOn ? Qt.alpha(ColorService.accent, 0.25) : Qt.rgba(1,1,1,0.06)
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 250 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: SystemService.bluetoothOn ? Qt.alpha(ColorService.accent, 0.2) : Qt.rgba(1, 1, 1, 0.08)
                    Behavior on color { ColorAnimation { duration: 250 } }
                    Text {
                        anchors.centerIn: parent
                        text: SystemService.bluetoothOn ? "󰂯" : "󰂲"
                        font.family: Theme.fontIcon
                        font.pixelSize: 18
                        color: SystemService.bluetoothOn ? ColorService.accent : ColorService.textSecondary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Bluetooth Adapter"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }
                    Text {
                        text: SystemService.bluetoothOn
                            ? (SystemService.isScanningBt ? "Scanning for devices…" : "Active")
                            : "Turned off"
                        font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary
                    }
                }

                M3Switch { checked: SystemService.bluetoothOn; onToggled: SystemService.toggleBluetooth() }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: SystemService.bluetoothOn

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Discovered Devices"
                    font.family: Theme.fontMain
                    font.pixelSize: 15
                    font.bold: true
                    color: ColorService.textPrimary
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: scanRow.implicitWidth + 24
                    height: 30; radius: 15
                    color: scanBtMouse.containsMouse ? Qt.alpha(ColorService.accent, 0.2) : Qt.alpha(ColorService.accent, 0.1)
                    border.color: Qt.alpha(ColorService.accent, 0.3); border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: scanRow
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: SystemService.isScanningBt ? "󰑐" : "󰑐"; font.family: Theme.fontIcon; font.pixelSize: 12; color: ColorService.accent }
                        Text { text: SystemService.isScanningBt ? "Scanning…" : "Scan"; font.family: Theme.fontMain; font.pixelSize: 12; font.bold: true; color: ColorService.accent }
                    }

                    MouseArea {
                        id: scanBtMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemService.scanBluetooth()
                    }
                }
            }

            Repeater {
                model: SystemService.bluetoothDevices
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 64
                    radius: 16
                    color: modelData.connected
                        ? Qt.alpha(ColorService.accent, 0.14)
                        : (btItemMa.containsMouse ? Qt.rgba(1,1,1,0.06) : ColorService.bgSurface)
                    border.color: modelData.connected ? ColorService.accent : "transparent"
                    border.width: modelData.connected ? 1.5 : 0
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            width: 38; height: 38; radius: 19
                            color: modelData.connected ? Qt.alpha(ColorService.accent, 0.2) : Qt.rgba(1,1,1,0.07)
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Text {
                                anchors.centerIn: parent
                                text: "󰂯"
                                font.family: Theme.fontIcon
                                font.pixelSize: 18
                                color: modelData.connected ? ColorService.accent : ColorService.textSecondary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text {
                                text: modelData.name || "Bluetooth Device"
                                font.family: Theme.fontMain
                                font.pixelSize: 13
                                font.bold: modelData.connected
                                color: ColorService.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: modelData.connected ? "Connected" : "Available"
                                font.family: Theme.fontMain
                                font.pixelSize: 11
                                color: modelData.connected ? ColorService.accent : ColorService.textSecondary
                            }
                        }

                        Rectangle {
                            implicitWidth: btActionTxt.implicitWidth + 20
                            height: 30; radius: 15
                            color: btActionMa.containsMouse
                                ? (modelData.connected ? Qt.alpha(ColorService.danger, 0.2) : Qt.alpha(ColorService.accent, 0.25))
                                : (modelData.connected ? Qt.alpha(ColorService.danger, 0.1) : Qt.alpha(ColorService.accent, 0.12))
                            border.color: modelData.connected
                                ? Qt.alpha(ColorService.danger, 0.4)
                                : Qt.alpha(ColorService.accent, 0.35)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: btActionTxt
                                anchors.centerIn: parent
                                text: modelData.connected ? "Disconnect" : "Pair"
                                font.family: Theme.fontMain
                                font.pixelSize: 12
                                font.bold: true
                                color: modelData.connected ? ColorService.danger : ColorService.accent
                            }

                            MouseArea {
                                id: btActionMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.connected) {
                                        SystemService.disconnectBluetooth(modelData.address)
                                    } else {
                                        SystemService.connectBluetooth(modelData.address)
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: btItemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: false
                    }
                }
            }

            Rectangle {
                visible: SystemService.bluetoothDevices.length === 0
                Layout.fillWidth: true
                height: 64; radius: 16
                color: ColorService.bgSurface
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "󰂲"; font.family: Theme.fontIcon; font.pixelSize: 22; color: ColorService.textSecondary; Layout.alignment: Qt.AlignHCenter }
                    Text { text: "No devices found — tap Scan"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary; Layout.alignment: Qt.AlignHCenter }
                }
            }
        }

        Item { height: 16 }
    }
}
