import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."
import "../services"

PopupWindow {
    id: menuRoot

    implicitWidth: 170
    implicitHeight: layout.implicitHeight + 16
    visible: false
    color: "transparent"
    grabFocus: true

    property real popupX: 0
    property var itemData: null

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(ColorService.bgElevated.r, ColorService.bgElevated.g, ColorService.bgElevated.b, 0.98)
        radius: Theme.radiusMedium
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            Text {
                text: itemData ? itemData.displayName : ""
                color: ColorService.textSecondary
                font.family: Theme.fontMain
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.topMargin: 4
                Layout.bottomMargin: 4
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: Theme.radiusSmall
                color: mousePin.containsMouse ? ColorService.bgHover : "transparent"

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 8
                    Text {
                        text: itemData && itemData.isPinned ? "Unpin from shelf" : "Pin to shelf"
                        color: ColorService.textPrimary
                        font.family: Theme.fontMain
                        font.pixelSize: 13
                    }
                }
                MouseArea {
                    id: mousePin
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        menuRoot.visible = false;
                        if (itemData && itemData.togglePin) itemData.togglePin();
                    }
                }
            }
        }
    }
}
