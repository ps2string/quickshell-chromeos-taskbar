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

        // Header
        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true

            Text { text: "Typography"; font.family: Theme.fontMain; font.pixelSize: 22; font.bold: true; color: ColorService.textPrimary }
            Text { text: "System fonts, icon font families, and UI scaling"; font.family: Theme.fontMain; font.pixelSize: 13; color: ColorService.textSecondary }
        }

        // --- Font Cards ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: fontCol.implicitHeight + 28
            radius: 20
            color: ColorService.bgSurface

            ColumnLayout {
                id: fontCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 16

                // Main Font
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Rectangle { width: 36; height: 36; radius: 18; color: Qt.alpha(ColorService.accent, 0.15)
                        Text { anchors.centerIn: parent; text: "󰬴"; font.family: Theme.fontIcon; font.pixelSize: 16; color: ColorService.accent }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                        Text { text: "UI Font Family"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }
                        Rectangle {
                            Layout.fillWidth: true; height: 36; radius: 8; color: Qt.rgba(1,1,1,0.06); border.color: Qt.rgba(1,1,1,0.1)
                            TextInput {
                                anchors.fill: parent; anchors.margins: 10; verticalAlignment: TextInput.AlignVCenter
                                text: Theme.fontMain; color: ColorService.textPrimary; font.family: Theme.fontMain; font.pixelSize: 13
                                onEditingFinished: { Theme.fontMain = text; Theme.save() }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.06) }

                // Icon Font
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Rectangle { width: 36; height: 36; radius: 18; color: Qt.alpha(ColorService.accent, 0.15)
                        Text { anchors.centerIn: parent; text: "󰭻"; font.family: Theme.fontIcon; font.pixelSize: 16; color: ColorService.accent }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                        Text { text: "Icon Font Family"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }
                        Rectangle {
                            Layout.fillWidth: true; height: 36; radius: 8; color: Qt.rgba(1,1,1,0.06); border.color: Qt.rgba(1,1,1,0.1)
                            TextInput {
                                anchors.fill: parent; anchors.margins: 10; verticalAlignment: TextInput.AlignVCenter
                                text: Theme.fontIcon; color: ColorService.textPrimary; font.family: Theme.fontMain; font.pixelSize: 13
                                onEditingFinished: { Theme.fontIcon = text; Theme.save() }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.06) }

                // UI Scale
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Rectangle { width: 36; height: 36; radius: 18; color: Qt.alpha(ColorService.accent, 0.15)
                        Text { anchors.centerIn: parent; text: "󰊩"; font.family: Theme.fontIcon; font.pixelSize: 16; color: ColorService.accent }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                        RowLayout { Layout.fillWidth: true
                            Text { text: "Global UI Scale"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }
                            Item { Layout.fillWidth: true }
                            Text { text: Math.round(Theme.uiScale * 100) + "%"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary }
                        }
                        Item {
                            id: scaleWrapper; Layout.fillWidth: true; height: 24
                            property real val: Theme.uiScale
                            Connections {
                                target: Theme
                                function onUiScaleChanged() { if (!scaleMouse.pressed) scaleWrapper.val = Theme.uiScale }
                            }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Qt.rgba(1,1,1,0.12)
                                Rectangle { width: parent.width * ((scaleWrapper.val - 0.5) / (2.0 - 0.5)); height: parent.height; radius: 3; color: ColorService.accent }
                            }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; x: Math.max(0, Math.min(parent.width - width, (parent.width - width) * ((scaleWrapper.val - 0.5) / (2.0 - 0.5)))); width: 20; height: 20; radius: 10; color: scaleMouse.pressed ? Qt.lighter(ColorService.accent, 1.3) : ColorService.accent; scale: scaleMouse.pressed ? 1.2 : 1; Behavior on scale { NumberAnimation { duration: 120 } } }
                            MouseArea { id: scaleMouse; anchors.fill: parent; preventStealing: true
                                function upd(m) { let v = Math.max(0.5, Math.min(2.0, 0.5 + (m.x / width) * (2.0 - 0.5))); scaleWrapper.val = v; Theme.uiScale = v; }
                                onPressed: (m) => upd(m); onPositionChanged: (m) => { if (pressed) upd(m) }
                                onReleased: Theme.save()
                            }
                        }
                    }
                }
            }
        }

        Item { height: 16 }
    }
}
