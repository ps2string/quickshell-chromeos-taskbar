import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import ".."

Rectangle {
    id: dockItemRoot
    
    property var toplevel
    
    width: 40
    height: 40
    radius: Theme.radiusMedium
    color: itemArea.containsMouse ? Theme.bgHover : "transparent"

    Rectangle {
        anchors.centerIn: parent
        width: 32
        height: 32
        radius: Theme.radiusSmall
        color: (toplevel && toplevel.activated) ? Theme.accentDim : Theme.bgElevated

        IconImage {
            id: appIcon
            anchors.fill: parent
            anchors.margins: 4
            source: toplevel ? Quickshell.iconPath(toplevel.appId.toLowerCase(), true) : ""
            visible: backer.status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            visible: appIcon.backer.status !== Image.Ready
            text: (toplevel && toplevel.appId) ? toplevel.appId.substring(0, 1).toUpperCase() : "?"
            color: (toplevel && toplevel.activated) ? Theme.accent : Theme.textPrimary
            font.family: Theme.fontMain
            font.bold: true
            font.pixelSize: 15
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        width: (toplevel && toplevel.activated) ? 16 : 4
        height: 3
        radius: 2
        color: (toplevel && toplevel.activated) ? Theme.accent : Theme.textSecondary
        Behavior on width { NumberAnimation { duration: 150 } }
    }

    MouseArea {
        id: itemArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: { if (toplevel) toplevel.activate(); }
    }
}
