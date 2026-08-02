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

        // ── Header ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Rectangle {
                width: 48; height: 48; radius: 24
                color: Qt.alpha(ColorService.accent, SystemService.wifiEnabled ? 0.18 : 0.08)
                Behavior on color { ColorAnimation { duration: 300 } }
                Text {
                    anchors.centerIn: parent
                    text: SystemService.wifiEnabled ? (SystemService.wifiConnected ? "󰤨" : "󰤭") : "󰤮"
                    font.family: Theme.fontIcon
                    font.pixelSize: 22
                    color: SystemService.wifiEnabled ? ColorService.accent : ColorService.textSecondary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    text: "Network & Wi-Fi"
                    font.family: Theme.fontMain
                    font.pixelSize: 22
                    font.bold: true
                    color: ColorService.textPrimary
                }
                Text {
                    text: SystemService.wifiConnected
                        ? "Connected to " + SystemService.wifiSsid
                        : (SystemService.wifiEnabled ? "Wi-Fi on — not connected" : "Manage connections and adapters")
                    font.family: Theme.fontMain
                    font.pixelSize: 13
                    color: SystemService.wifiConnected ? ColorService.accent : ColorService.textSecondary
                }
            }
        }

        // ── Wi-Fi Master Toggle ────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 68
            radius: 20
            color: ColorService.bgSurface
            border.color: SystemService.wifiEnabled ? Qt.alpha(ColorService.accent, 0.25) : Qt.rgba(1,1,1,0.06)
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 250 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: SystemService.wifiEnabled ? Qt.alpha(ColorService.accent, 0.2) : Qt.rgba(1, 1, 1, 0.08)
                    Behavior on color { ColorAnimation { duration: 250 } }
                    Text {
                        anchors.centerIn: parent
                        text: SystemService.wifiEnabled ? "󰤨" : "󰤮"
                        font.family: Theme.fontIcon
                        font.pixelSize: 18
                        color: SystemService.wifiEnabled ? ColorService.accent : ColorService.textSecondary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Wi-Fi Radio"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }
                    Text {
                        text: SystemService.wifiEnabled
                            ? (SystemService.wifiConnected ? "Connected to " + SystemService.wifiSsid : "Enabled — scanning…")
                            : "Disabled"
                        font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary
                    }
                }

                M3Switch { checked: SystemService.wifiEnabled; onToggled: SystemService.toggleWifi() }
            }
        }

        // ── Available Networks ─────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: SystemService.wifiEnabled

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Available Networks"
                    font.family: Theme.fontMain
                    font.pixelSize: 15
                    font.bold: true
                    color: ColorService.textPrimary
                    Layout.fillWidth: true
                }

                // Scan button
                Rectangle {
                    width: 80; height: 30; radius: 15
                    color: scanMouse.containsMouse ? Qt.alpha(ColorService.accent, 0.2) : Qt.alpha(ColorService.accent, 0.1)
                    border.color: Qt.alpha(ColorService.accent, 0.3); border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "󰑐"; font.family: Theme.fontIcon; font.pixelSize: 12; color: ColorService.accent }
                        Text { text: "Scan"; font.family: Theme.fontMain; font.pixelSize: 12; font.bold: true; color: ColorService.accent }
                    }
                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemService.scanWifi()
                    }
                }
            }

            Repeater {
                model: SystemService.wifiNetworks
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 60
                    radius: 16
                    color: modelData.inUse
                        ? Qt.alpha(ColorService.accent, 0.14)
                        : (netMa.containsMouse ? Qt.rgba(1,1,1,0.06) : ColorService.bgSurface)
                    border.color: modelData.inUse ? ColorService.accent : "transparent"
                    border.width: modelData.inUse ? 1.5 : 0
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        // Signal icon with strength color
                        Text {
                            text: modelData.signal > 70 ? "󰤨" : (modelData.signal > 40 ? "󰤥" : (modelData.signal > 15 ? "󰤢" : "󰤟"))
                            font.family: Theme.fontIcon
                            font.pixelSize: 20
                            color: modelData.inUse ? ColorService.accent
                                 : (modelData.signal > 60 ? ColorService.textPrimary : ColorService.textSecondary)
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Text {
                                    text: modelData.ssid
                                    font.family: Theme.fontMain
                                    font.pixelSize: 13
                                    font.bold: modelData.inUse
                                    color: ColorService.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                // Security badge
                                Rectangle {
                                    visible: (modelData.security || "").length > 0 && !modelData.inUse
                                    implicitWidth: secTxt.implicitWidth + 10
                                    height: 18; radius: 9
                                    color: Qt.rgba(1,1,1,0.07)
                                    Text {
                                        id: secTxt
                                        anchors.centerIn: parent
                                        text: "󰌾"
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 10
                                        color: ColorService.textSecondary
                                    }
                                }
                            }

                            // Signal bar
                            Row {
                                spacing: 2
                                Repeater {
                                    model: 4
                                    Rectangle {
                                        width: 5; radius: 2
                                        height: 4 + index * 3
                                        anchors.bottom: parent ? parent.bottom : undefined
                                        color: (modelData.signal / 25) > index
                                            ? (modelData.inUse ? ColorService.accent : ColorService.textPrimary)
                                            : Qt.rgba(1,1,1,0.15)
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }
                            }
                        }

                        // Connect / Connected badge
                        Rectangle {
                            visible: modelData.inUse
                            implicitWidth: connectedTxt.implicitWidth + 18
                            height: 28; radius: 14
                            color: Qt.alpha(ColorService.accent, 0.15)
                            border.color: Qt.alpha(ColorService.accent, 0.4); border.width: 1
                            Text {
                                id: connectedTxt
                                anchors.centerIn: parent
                                text: "󰄬  Connected"
                                font.family: Theme.fontMain
                                font.pixelSize: 11
                                font.bold: true
                                color: ColorService.accent
                            }
                        }

                        Rectangle {
                            visible: !modelData.inUse
                            implicitWidth: connectTxt.implicitWidth + 20
                            height: 30; radius: 15
                            color: connBtnMa.containsMouse ? Qt.alpha(ColorService.accent, 0.25) : Qt.alpha(ColorService.accent, 0.12)
                            border.color: Qt.alpha(ColorService.accent, 0.35); border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text {
                                id: connectTxt
                                anchors.centerIn: parent
                                text: "Connect"
                                font.family: Theme.fontMain
                                font.pixelSize: 12
                                font.bold: true
                                color: ColorService.accent
                            }
                            MouseArea {
                                id: connBtnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SystemService.connectWifi(modelData.ssid, "")
                            }
                        }
                    }

                    MouseArea {
                        id: netMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: modelData.inUse
                    }
                }
            }

            // Empty state
            Rectangle {
                visible: SystemService.wifiNetworks.length === 0
                Layout.fillWidth: true
                height: 64; radius: 16
                color: ColorService.bgSurface
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "󰤮"; font.family: Theme.fontIcon; font.pixelSize: 22; color: ColorService.textSecondary; Layout.alignment: Qt.AlignHCenter }
                    Text { text: "No networks found — tap Scan"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary; Layout.alignment: Qt.AlignHCenter }
                }
            }
        }

        Item { height: 16 }
    }
}
