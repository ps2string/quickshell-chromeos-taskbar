import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire as Pw
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

        ColumnLayout {
            spacing: 4; Layout.fillWidth: true
            Text { text: "Sound & Display"; font.family: Theme.fontMain; font.pixelSize: 22; font.bold: true; color: ColorService.textPrimary }
            Text { text: "Volume, brightness, audio devices, and display toggles"; font.family: Theme.fontMain; font.pixelSize: 13; color: ColorService.textSecondary }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: slidersCol.implicitHeight + 32
            radius: 22
            color: ColorService.bgSurface
            border.color: Qt.rgba(1,1,1,0.06); border.width: 1

            ColumnLayout {
                id: slidersCol; anchors.fill: parent; anchors.margins: 18; spacing: 20

                Text { text: "Controls"; font.family: Theme.fontMain; font.pixelSize: 12; font.bold: true; color: ColorService.textSecondary; font.letterSpacing: 1.2 }

                RowLayout {
                    Layout.fillWidth: true; spacing: 14

                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: Qt.alpha(SystemService.isMuted ? ColorService.danger : ColorService.accent, 0.15)
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Text {
                            anchors.centerIn: parent
                            text: SystemService.isMuted ? "󰖁" : (SystemService.volume > 60 ? "󰕾" : (SystemService.volume > 0 ? "󰖀" : "󰕿"))
                            font.family: Theme.fontIcon; font.pixelSize: 18
                            color: SystemService.isMuted ? ColorService.danger : ColorService.accent
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: SystemService.toggleMute() }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Master Volume"; font.family: Theme.fontMain; font.pixelSize: 13; font.bold: true; color: ColorService.textPrimary }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                implicitWidth: volPctTxt.implicitWidth + 14
                                height: 20; radius: 10
                                color: Qt.alpha(SystemService.isMuted ? ColorService.danger : ColorService.accent, 0.12)
                                Text {
                                    id: volPctTxt
                                    anchors.centerIn: parent
                                    text: SystemService.isMuted ? "Muted" : (Math.round(SystemService.volume) + "%")
                                    font.family: Theme.fontMain; font.pixelSize: 11; font.bold: true
                                    color: SystemService.isMuted ? ColorService.danger : ColorService.accent
                                }
                            }
                        }

                        Item {
                            id: volWrapper; Layout.fillWidth: true; height: 28
                            property real val: SystemService.volume || 0
                            Connections { target: SystemService; function onVolumeChanged() { if (!volMouse.pressed) volWrapper.val = SystemService.volume || 0 } }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 6; radius: 3
                                color: Qt.rgba(1,1,1,0.10)
                                Rectangle {
                                    width: parent.width * (volWrapper.val / 100)
                                    height: parent.height; radius: 3
                                    color: SystemService.isMuted ? ColorService.danger : ColorService.accent
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Behavior on width { NumberAnimation { duration: 60 } }
                                }
                            }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(parent.width - width, (parent.width - width) * (volWrapper.val / 100)))
                                width: volMouse.pressed ? 22 : 20; height: width; radius: width / 2
                                color: SystemService.isMuted ? ColorService.danger : (volMouse.pressed ? Qt.lighter(ColorService.accent, 1.3) : ColorService.accent)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on width { NumberAnimation { duration: 120 } }
                                border.color: Qt.rgba(0,0,0,0.25); border.width: 1
                            }
                            MouseArea {
                                id: volMouse; anchors.fill: parent; preventStealing: true; cursorShape: Qt.PointingHandCursor
                                function upd(m) { let v = Math.max(0, Math.min(100, (m.x / width) * 100)); volWrapper.val = v; SystemService.setVolume(v) }
                                onPressed: (m) => upd(m)
                                onPositionChanged: (m) => { if (pressed) upd(m) }
                                onWheel: (w) => { let v = Math.max(0, Math.min(100, volWrapper.val + (w.angleDelta.y > 0 ? 5 : -5))); volWrapper.val = v; SystemService.setVolume(v) }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.06) }

                RowLayout {
                    Layout.fillWidth: true; spacing: 14

                    Rectangle {
                        width: 40; height: 40; radius: 20; color: Qt.alpha(ColorService.accent, 0.15)
                        Text {
                            anchors.centerIn: parent
                            text: SystemService.brightness > 60 ? "󰃠" : (SystemService.brightness > 30 ? "󰃟" : "󰃞")
                            font.family: Theme.fontIcon; font.pixelSize: 18; color: ColorService.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Brightness"; font.family: Theme.fontMain; font.pixelSize: 13; font.bold: true; color: ColorService.textPrimary }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                implicitWidth: briPctTxt.implicitWidth + 14
                                height: 20; radius: 10
                                color: Qt.alpha(ColorService.accent, 0.12)
                                Text {
                                    id: briPctTxt
                                    anchors.centerIn: parent
                                    text: Math.round(brightWrapper.val) + "%"
                                    font.family: Theme.fontMain; font.pixelSize: 11; font.bold: true; color: ColorService.accent
                                }
                            }
                        }

                        Item {
                            id: brightWrapper; Layout.fillWidth: true; height: 28
                            property real val: SystemService.brightness || 50
                            Connections { target: SystemService; function onBrightnessChanged() { if (!brightMouse.pressed) brightWrapper.val = SystemService.brightness || 50 } }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 6; radius: 3; color: Qt.rgba(1,1,1,0.10)
                                Rectangle {
                                    width: parent.width * (brightWrapper.val / 100)
                                    height: parent.height; radius: 3; color: ColorService.accent
                                    Behavior on width { NumberAnimation { duration: 60 } }
                                }
                            }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(parent.width - width, (parent.width - width) * (brightWrapper.val / 100)))
                                width: brightMouse.pressed ? 22 : 20; height: width; radius: width / 2
                                color: brightMouse.pressed ? Qt.lighter(ColorService.accent, 1.3) : ColorService.accent
                                Behavior on width { NumberAnimation { duration: 120 } }
                                border.color: Qt.rgba(0,0,0,0.25); border.width: 1
                            }
                            MouseArea {
                                id: brightMouse; anchors.fill: parent; preventStealing: true; cursorShape: Qt.PointingHandCursor
                                function upd(m) { let v = Math.max(5, Math.min(100, (m.x / width) * 100)); brightWrapper.val = v; SystemService.setBrightness(v) }
                                onPressed: (m) => upd(m)
                                onPositionChanged: (m) => { if (pressed) upd(m) }
                                onWheel: (w) => { let v = Math.max(5, Math.min(100, brightWrapper.val + (w.angleDelta.y > 0 ? 5 : -5))); brightWrapper.val = v; SystemService.setBrightness(v) }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: togglesCol.implicitHeight + 32
            radius: 22; color: ColorService.bgSurface
            border.color: Qt.rgba(1,1,1,0.06); border.width: 1

            ColumnLayout {
                id: togglesCol; anchors.fill: parent; anchors.margins: 18; spacing: 0

                Text { text: "Display"; font.family: Theme.fontMain; font.pixelSize: 12; font.bold: true; color: ColorService.textSecondary; font.letterSpacing: 1.2; bottomPadding: 14 }

                RowLayout {
                    Layout.fillWidth: true; spacing: 14; height: 56

                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: Qt.alpha(SystemService.nightLightOn ? "#ff9d6f" : ColorService.accent, SystemService.nightLightOn ? 0.2 : 0.08)
                        Behavior on color { ColorAnimation { duration: 250 } }
                        Text {
                            anchors.centerIn: parent; text: SystemService.nightLightOn ? "󰛮" : "󰛩"
                            font.family: Theme.fontIcon; font.pixelSize: 18
                            color: SystemService.nightLightOn ? "#ff9d6f" : ColorService.textSecondary
                        }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                        Text { text: "Night Light"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }
                        Text { text: SystemService.nightLightOn ? "Active · reducing blue light (4500K)" : "Reduces blue light after sunset"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary }
                    }
                    M3Switch { checked: SystemService.nightLightOn; onToggled: SystemService.toggleNightLight() }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.06) }

                RowLayout {
                    Layout.fillWidth: true; spacing: 14; height: 56

                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: Qt.alpha(SystemService.dndActive ? ColorService.danger : ColorService.accent, 0.12)
                        Behavior on color { ColorAnimation { duration: 250 } }
                        Text {
                            anchors.centerIn: parent; text: SystemService.dndActive ? "󰂛" : "󰖔"
                            font.family: Theme.fontIcon; font.pixelSize: 18
                            color: SystemService.dndActive ? ColorService.danger : ColorService.textSecondary
                        }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                        Text { text: "Do Not Disturb"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }
                        Text { text: SystemService.dndActive ? "All notifications silenced" : "Silence all notification popups"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary }
                    }
                    M3Switch { checked: SystemService.dndActive; onToggled: SystemService.toggleDnd() }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Output"; font.family: Theme.fontMain; font.pixelSize: 15; font.bold: true; color: ColorService.textPrimary }
                Item { Layout.fillWidth: true }
                Text { text: "Speakers & Headphones"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary }
            }

            Repeater {
                model: SystemService.audioOutputs
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true; height: 60; radius: 16
                    color: modelData.inUse ? Qt.alpha(ColorService.accent, 0.14) : (outMa.containsMouse ? Qt.rgba(1,1,1,0.06) : ColorService.bgSurface)
                    border.color: modelData.inUse ? ColorService.accent : "transparent"
                    border.width: modelData.inUse ? 1.5 : 0
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 14; spacing: 12

                        Rectangle {
                            width: 36; height: 36; radius: 18
                            color: Qt.alpha(modelData.inUse ? ColorService.accent : ColorService.textSecondary, 0.12)
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Text {
                                anchors.centerIn: parent
                                text: (modelData.deviceLabel || "").toLowerCase().includes("head") ? "󰋋"
                                    : (modelData.deviceLabel || "").toLowerCase().includes("hdmi") ? "󰡁"
                                    : "󰓃"
                                font.family: Theme.fontIcon; font.pixelSize: 16
                                color: modelData.inUse ? ColorService.accent : ColorService.textSecondary
                            }
                        }

                        Text {
                            text: modelData.deviceLabel
                            font.family: Theme.fontMain; font.pixelSize: 13; font.bold: modelData.inUse
                            color: ColorService.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true
                        }

                        Text {
                            visible: modelData.inUse
                            text: "󰄬"
                            font.family: Theme.fontIcon; font.pixelSize: 16; color: ColorService.accent
                        }
                    }

                    MouseArea { id: outMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SystemService.setAudioOutput(modelData) }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Input"; font.family: Theme.fontMain; font.pixelSize: 15; font.bold: true; color: ColorService.textPrimary }
                Item { Layout.fillWidth: true }
                Text { text: "Microphones"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary }
            }

            Repeater {
                model: SystemService.audioInputs
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true; height: 60; radius: 16
                    color: modelData.inUse ? Qt.alpha(ColorService.accent, 0.14) : (inMa.containsMouse ? Qt.rgba(1,1,1,0.06) : ColorService.bgSurface)
                    border.color: modelData.inUse ? ColorService.accent : "transparent"
                    border.width: modelData.inUse ? 1.5 : 0
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 14; spacing: 12

                        Rectangle {
                            width: 36; height: 36; radius: 18
                            color: Qt.alpha(modelData.inUse ? ColorService.accent : ColorService.textSecondary, 0.12)
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Text { anchors.centerIn: parent; text: "󰍬"; font.family: Theme.fontIcon; font.pixelSize: 16; color: modelData.inUse ? ColorService.accent : ColorService.textSecondary }
                        }

                        Text {
                            text: modelData.deviceLabel
                            font.family: Theme.fontMain; font.pixelSize: 13; font.bold: modelData.inUse
                            color: ColorService.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true
                        }

                        Text { visible: modelData.inUse; text: "󰄬"; font.family: Theme.fontIcon; font.pixelSize: 16; color: ColorService.accent }
                    }

                    MouseArea { id: inMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SystemService.setAudioInput(modelData) }
                }
            }
        }

        Item { height: 16 }
    }
}
