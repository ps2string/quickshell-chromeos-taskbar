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

    ColumnLayout {
        width: root.availableWidth - 16
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20

        Item { height: 4 }

        // Header
        ColumnLayout {
            spacing: 4; Layout.fillWidth: true
            Text { text: "Bar & Dock"; font.family: Theme.fontMain; font.pixelSize: 22; font.bold: true; color: ColorService.textPrimary }
            Text { text: "Configure bottom bar height, dock behavior, icon sizes, and workspace badges"; font.family: Theme.fontMain; font.pixelSize: 13; color: ColorService.textSecondary; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }

        // --- Dock Toggles Card ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: dockCol.implicitHeight + 28
            radius: 20; color: ColorService.bgSurface

            ColumnLayout {
                id: dockCol; anchors.fill: parent; anchors.margins: 14; spacing: 16

                // Show Unpinned Apps
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Rectangle { width: 36; height: 36; radius: 18; color: Qt.alpha(ColorService.accent, 0.15)
                        Text { anchors.centerIn: parent; text: "󱂬"; font.family: Theme.fontIcon; font.pixelSize: 16; color: ColorService.accent }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                        Text { text: "Show Unpinned Apps"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }
                        Text { text: "Display open, unpinned windows in the center dock shelf"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    }
                    M3Switch { checked: DockSettingsService.showUnpinned; onToggled: { DockSettingsService.showUnpinned = !DockSettingsService.showUnpinned; DockSettingsService.save() } }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.06) }

                // Expressive Workspace Badges
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Rectangle { width: 36; height: 36; radius: 18; color: Qt.alpha(ColorService.accent, 0.15)
                        Text { anchors.centerIn: parent; text: "󰒟"; font.family: Theme.fontIcon; font.pixelSize: 16; color: ColorService.accent }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                        Text { text: "Expressive Workspace Badges"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }
                        Text { text: "Expand active workspace badge to show text label"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    }
                    M3Switch { checked: DockSettingsService.expressiveWorkspaces; onToggled: { DockSettingsService.expressiveWorkspaces = !DockSettingsService.expressiveWorkspaces; DockSettingsService.save() } }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.06) }

                // Show Seconds in Clock
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Rectangle { width: 36; height: 36; radius: 18; color: Qt.alpha(ColorService.accent, 0.15)
                        Text { anchors.centerIn: parent; text: "󱑂"; font.family: Theme.fontIcon; font.pixelSize: 16; color: ColorService.accent }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                        Text { text: "Show Seconds"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }
                        Text { text: "Display seconds in the status bar clock"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary }
                    }
                    M3Switch { checked: DockSettingsService.showSeconds; onToggled: { DockSettingsService.showSeconds = !DockSettingsService.showSeconds; DockSettingsService.save() } }
                }
            }
        }

        // --- Bar Height Slider ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: heightCol.implicitHeight + 28
            radius: 20; color: ColorService.bgSurface

            ColumnLayout {
                id: heightCol; anchors.fill: parent; anchors.margins: 16; spacing: 14

                RowLayout { Layout.fillWidth: true; spacing: 12
                    Rectangle { width: 36; height: 36; radius: 18; color: Qt.alpha(ColorService.accent, 0.15)
                        Text { anchors.centerIn: parent; text: "󰁌"; font.family: Theme.fontIcon; font.pixelSize: 16; color: ColorService.accent }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                        RowLayout { Layout.fillWidth: true
                            Text { text: "Bar Height"; font.family: Theme.fontMain; font.pixelSize: 13; font.bold: true; color: ColorService.textPrimary }
                            Item { Layout.fillWidth: true }
                            Text { text: DockSettingsService.barHeight + "px"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary }
                        }
                        Item {
                            id: barHeightWrapper; Layout.fillWidth: true; height: 24
                            property real val: DockSettingsService.barHeight
                            Connections {
                                target: DockSettingsService
                                function onBarHeightChanged() { if (!barHMouse.pressed) barHeightWrapper.val = DockSettingsService.barHeight }
                            }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Qt.rgba(1,1,1,0.12)
                                Rectangle { width: parent.width * ((barHeightWrapper.val - 48) / (96 - 48)); height: parent.height; radius: 3; color: ColorService.accent }
                            }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; x: Math.max(0, Math.min(parent.width - width, (parent.width - width) * ((barHeightWrapper.val - 48) / (96 - 48)))); width: 20; height: 20; radius: 10; color: barHMouse.pressed ? Qt.lighter(ColorService.accent, 1.3) : ColorService.accent; scale: barHMouse.pressed ? 1.2 : 1; Behavior on scale { NumberAnimation { duration: 120 } } }
                            MouseArea { id: barHMouse; anchors.fill: parent; preventStealing: true
                                function upd(m) { let v = Math.round(Math.max(48, Math.min(96, 48 + (m.x / width) * (96 - 48)))); barHeightWrapper.val = v; DockSettingsService.barHeight = v; }
                                onPressed: (m) => upd(m); onPositionChanged: (m) => { if (pressed) upd(m) }
                                onReleased: DockSettingsService.save()
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.06) }

                RowLayout { Layout.fillWidth: true; spacing: 12
                    Rectangle { width: 36; height: 36; radius: 18; color: Qt.alpha(ColorService.accent, 0.15)
                        Text { anchors.centerIn: parent; text: "󰍉"; font.family: Theme.fontIcon; font.pixelSize: 16; color: ColorService.accent }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                        RowLayout { Layout.fillWidth: true
                            Text { text: "Icon Size"; font.family: Theme.fontMain; font.pixelSize: 13; font.bold: true; color: ColorService.textPrimary }
                            Item { Layout.fillWidth: true }
                            Text { text: DockSettingsService.dockIconSize + "px"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary }
                        }
                        Item {
                            id: iconSzWrapper; Layout.fillWidth: true; height: 24
                            property real val: DockSettingsService.dockIconSize
                            Connections {
                                target: DockSettingsService
                                function onDockIconSizeChanged() { if (!iconSzMouse.pressed) iconSzWrapper.val = DockSettingsService.dockIconSize }
                            }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Qt.rgba(1,1,1,0.12)
                                Rectangle { width: parent.width * ((iconSzWrapper.val - 18) / (40 - 18)); height: parent.height; radius: 3; color: ColorService.accent }
                            }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; x: Math.max(0, Math.min(parent.width - width, (parent.width - width) * ((iconSzWrapper.val - 18) / (40 - 18)))); width: 20; height: 20; radius: 10; color: iconSzMouse.pressed ? Qt.lighter(ColorService.accent, 1.3) : ColorService.accent; scale: iconSzMouse.pressed ? 1.2 : 1; Behavior on scale { NumberAnimation { duration: 120 } } }
                            MouseArea { id: iconSzMouse; anchors.fill: parent; preventStealing: true
                                function upd(m) { let v = Math.round(Math.max(18, Math.min(40, 18 + (m.x / width) * (40 - 18)))); iconSzWrapper.val = v; DockSettingsService.dockIconSize = v; }
                                onPressed: (m) => upd(m); onPositionChanged: (m) => { if (pressed) upd(m) }
                                onReleased: DockSettingsService.save()
                            }
                        }
                    }
                }
            }
        }

        // --- Pinned Apps Management ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: pinsCol.implicitHeight + 28
            radius: 20; color: ColorService.bgSurface

            ColumnLayout {
                id: pinsCol; anchors.fill: parent; anchors.margins: 16; spacing: 10

                RowLayout { Layout.fillWidth: true
                    Text { text: "Pinned Apps"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }
                    Item { Layout.fillWidth: true }
                    Text { text: PinsService.pins.length + " pinned"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary }
                }
                Text { text: "Right-click any app in the dock to pin/unpin it. Drag to reorder."; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary; wrapMode: Text.WordWrap; Layout.fillWidth: true }

                Repeater {
                    model: PinsService.pins
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true; height: 44; radius: 12
                        color: Qt.alpha(ColorService.accent, 0.08)
                        RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 10
                            Text { text: modelData.icon || ""; font.family: Theme.fontIcon; font.pixelSize: 16; color: ColorService.accent }
                            Text { text: modelData.name || modelData.appId || "App"; font.family: Theme.fontMain; font.pixelSize: 13; color: ColorService.textPrimary; Layout.fillWidth: true }
                            Rectangle {
                                width: 26; height: 26; radius: 13
                                color: unpinMouse.containsMouse ? ColorService.danger : Qt.alpha(ColorService.danger, 0.15)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text { anchors.centerIn: parent; text: "󰅖"; font.family: Theme.fontIcon; font.pixelSize: 12; color: unpinMouse.containsMouse ? "white" : ColorService.danger }
                                MouseArea { id: unpinMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: PinsService.unpin(modelData.appId) }
                            }
                        }
                    }
                }

                Text {
                    visible: PinsService.pins.length === 0
                    text: "No pinned apps. Right-click any running app to pin it."; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Item { height: 16 }
    }
}
