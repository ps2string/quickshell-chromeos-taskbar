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

            // Reverted back to your original perfect circle style
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

            // Wayland-aware Context Menu Anchor (keeps the fix that makes it open upwards)
            QsMenuAnchor {
                id: menuAnchor
                menu: modelData.menu
                
                anchor {
                    item: itemDelegate
                    edges: Edges.Top
                    gravity: Edges.Top
                }
            }

            // Mouse interactions
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        if (modelData.hasMenu) {
                            menuAnchor.open();
                        }
                    } else if (mouse.button === Qt.LeftButton) {
                        modelData.activate();
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
