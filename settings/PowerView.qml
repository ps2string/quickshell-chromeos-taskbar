import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."
import "../services"

ScrollView {
    id: root
    anchors.fill: parent
    contentWidth: availableWidth
    clip: true

    property bool confirmVisible: false
    property string pendingAction: ""

    Process {
        id: actionProc
    }

    function doAction(action) {
        switch(action) {
            case "poweroff":  actionProc.command = ["systemctl", "poweroff"]; break;
            case "reboot":    actionProc.command = ["systemctl", "reboot"];   break;
            case "rebootfw":  actionProc.command = ["systemctl", "reboot", "--firmware-setup"]; break;
            case "suspend":   actionProc.command = ["systemctl", "suspend"];  break;
            case "hibernate": actionProc.command = ["systemctl", "hibernate"]; break;
            case "logout":    actionProc.command = ["hyprctl", "dispatch", "exit"]; break;
            case "lock":      actionProc.command = ["hyprlock"]; break;
            default: return;
        }
        actionProc.running = true;
        root.confirmVisible = false;
    }

    ColumnLayout {
        width: root.availableWidth - 16
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20

        Item { height: 4 }

        ColumnLayout {
            spacing: 4; Layout.fillWidth: true
            Text { text: "Power"; font.family: Theme.fontMain; font.pixelSize: 22; font.bold: true; color: ColorService.textPrimary }
            Text { text: "Shutdown, reboot, sleep, lock, and session options"; font.family: Theme.fontMain; font.pixelSize: 13; color: ColorService.textSecondary }
        }

        Rectangle {
            Layout.fillWidth: true; height: 80; radius: 20; color: ColorService.bgSurface

            RowLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 16

                Rectangle {
                    width: 48; height: 48; radius: 24
                    color: Qt.alpha(SystemService.batteryLevel <= 15 ? ColorService.danger : ColorService.accent, 0.15)
                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (SystemService.isCharging) return "󰂄";
                            let lvl = SystemService.batteryLevel;
                            if (lvl > 90) return "󰁹";
                            if (lvl > 70) return "󰂀";
                            if (lvl > 50) return "󰁾";
                            if (lvl > 30) return "󰁼";
                            if (lvl > 15) return "󰁺";
                            return "󰁻";
                        }
                        font.family: Theme.fontIcon; font.pixelSize: 24
                        color: SystemService.batteryLevel <= 15 ? ColorService.danger : ColorService.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4
                    RowLayout { Layout.fillWidth: true
                        Text {
                            text: SystemService.batteryLevel + "% — " + (SystemService.isCharging ? "Charging" : "On Battery")
                            font.family: Theme.fontMain; font.pixelSize: 15; font.bold: true
                            color: ColorService.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            visible: SystemService.batteryTime.length > 0
                            text: SystemService.batteryTime + " remaining"
                            font.family: Theme.fontMain; font.pixelSize: 12
                            color: ColorService.textSecondary
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 8; radius: 4
                        color: Qt.rgba(1,1,1,0.12)
                        Rectangle {
                            width: parent.width * (SystemService.batteryLevel / 100); height: parent.height; radius: 4
                            color: SystemService.batteryLevel <= 15 ? ColorService.danger : (SystemService.isCharging ? ColorService.success : ColorService.accent)
                            Behavior on width { NumberAnimation { duration: 500 } }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: pwrGrid.implicitHeight + 32
            radius: 20; color: ColorService.bgSurface

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 12

                Text { text: "Session"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }

                Rectangle {
                    Layout.fillWidth: true
                    visible: root.confirmVisible
                    height: 60; radius: 16
                    color: Qt.alpha(ColorService.danger, 0.15)
                    border.color: Qt.alpha(ColorService.danger, 0.4); border.width: 1
                    RowLayout { anchors.fill: parent; anchors.margins: 14; spacing: 12
                        Text { text: "Are you sure?"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.danger; Layout.fillWidth: true }
                        Rectangle {
                            implicitWidth: cancelTxt.implicitWidth + 20; height: 34; radius: 17
                            color: cancelM.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.08)
                            Text { id: cancelTxt; anchors.centerIn: parent; text: "Cancel"; font.family: Theme.fontMain; font.pixelSize: 13; color: ColorService.textPrimary }
                            MouseArea { id: cancelM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.confirmVisible = false }
                        }
                        Rectangle {
                            implicitWidth: confirmTxt.implicitWidth + 20; height: 34; radius: 17
                            color: confirmM.containsMouse ? ColorService.danger : Qt.alpha(ColorService.danger, 0.8)
                            Text { id: confirmTxt; anchors.centerIn: parent; text: "Confirm"; font.family: Theme.fontMain; font.pixelSize: 13; font.bold: true; color: "white" }
                            MouseArea { id: confirmM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.doAction(root.pendingAction) }
                        }
                    }
                }

                GridLayout {
                    id: pwrGrid
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Repeater {
                        model: [
                            { icon: "󰐥", label: "Power Off",     action: "poweroff",  color: "#f28b82", dangerous: true },
                            { icon: "󰑓", label: "Reboot",        action: "reboot",    color: "#fdd663", dangerous: true },
                            { icon: "󰒲", label: "Suspend",       action: "suspend",   color: "#78d9ec", dangerous: false },
                            { icon: "󰴻", label: "Hibernate",     action: "hibernate", color: "#c58af9", dangerous: false },
                            { icon: "󰌾", label: "Lock Screen",   action: "lock",      color: "#81c995", dangerous: false },
                            { icon: "󰍃", label: "Log Out",       action: "logout",    color: "#ff9d6f", dangerous: true },
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; height: 64; radius: 16
                            color: pwrMouse.containsMouse ? Qt.alpha(modelData.color, 0.25) : Qt.alpha(modelData.color, 0.1)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            scale: pwrMouse.containsMouse ? 1.02 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150 } }

                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 6
                                Text { text: modelData.icon; font.family: Theme.fontIcon; font.pixelSize: 22; color: modelData.color; Layout.alignment: Qt.AlignHCenter }
                                Text { text: modelData.label; font.family: Theme.fontMain; font.pixelSize: 12; font.bold: true; color: ColorService.textPrimary; Layout.alignment: Qt.AlignHCenter }
                            }

                            MouseArea { id: pwrMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.dangerous) {
                                        root.pendingAction = modelData.action;
                                        root.confirmVisible = true;
                                    } else {
                                        root.doAction(modelData.action);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: 52; radius: 16
            color: fwMouse.containsMouse ? Qt.alpha("#fdd663", 0.2) : ColorService.bgSurface
            Behavior on color { ColorAnimation { duration: 150 } }
            RowLayout { anchors.fill: parent; anchors.margins: 14; spacing: 12
                Text { text: "󰮫"; font.family: Theme.fontIcon; font.pixelSize: 18; color: "#fdd663" }
                ColumnLayout { Layout.fillWidth: true; spacing: 2
                    Text { text: "Reboot to Firmware (UEFI/BIOS)"; font.family: Theme.fontMain; font.pixelSize: 13; font.bold: true; color: ColorService.textPrimary }
                    Text { text: "Restart and enter firmware setup"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary }
                }
                Text { text: "󰌑"; font.family: Theme.fontIcon; font.pixelSize: 16; color: ColorService.textSecondary }
            }
            MouseArea { id: fwMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { root.pendingAction = "rebootfw"; root.confirmVisible = true; }
            }
        }

        Item { height: 16 }
    }
}
