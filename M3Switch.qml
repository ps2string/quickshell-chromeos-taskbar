import QtQuick
import "services"

Item {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 52
    implicitHeight: 32

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? ColorService.accent : Qt.rgba(1, 1, 1, 0.15)
        border.color: root.checked ? ColorService.accent : Qt.rgba(1, 1, 1, 0.3)
        border.width: 1.5
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }
    }

    Rectangle {
        id: thumb
        width: root.checked ? 24 : 20
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 4 : 4
        color: root.checked ? ColorService.bgBase : ColorService.textSecondary
        scale: switchArea.pressed ? 0.88 : 1.0

        Behavior on x      { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on color  { ColorAnimation  { duration: 200 } }
        Behavior on scale  { NumberAnimation { duration: 150 } }
    }

    MouseArea {
        id: switchArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
