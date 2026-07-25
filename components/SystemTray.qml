import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

RowLayout {
    id: trayRoot
    spacing: 4

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: itemDelegate
            required property SystemTrayItem modelData

            implicitWidth: 32
            implicitHeight: 32
            radius: 16
            color: mouseArea.containsMouse 
                ? Qt.rgba(1, 1, 1, 0.12) 
                : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            // Icon display
            IconImage {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: modelData.icon
            }

            // Right-click context menu anchor
            QsMenuAnchor {
                id: menuAnchor
                menu: modelData.menu
                anchor.window: trayRoot.Window.window
            }

            // Mouse interactions
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        if (modelData.hasMenu && menuAnchor.menu) {
                            menuAnchor.open();
                        } else {
                            modelData.contextMenu(mouse.x, mouse.y);
                        }
                    } else if (mouse.button === Qt.LeftButton) {
                        modelData.activate();
                    } else if (mouse.button === Qt.MiddleButton) {
                        modelData.secondaryActivate();
                    }
                }
            }

            // Tooltip
            ToolTip {
                visible: mouseArea.containsMouse && (modelData.tooltipTitle !== "" || modelData.title !== "")
                delay: 300
                text: modelData.tooltipTitle !== "" ? modelData.tooltipTitle : modelData.title
            }
        }
    }
}
