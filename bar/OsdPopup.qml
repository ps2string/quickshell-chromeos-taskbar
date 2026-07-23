import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."
import "../services"

// ChromeOS-style On-Screen Display (OSD) pill popout for Volume & Brightness changes
PopupWindow {
    id: osdRoot

    implicitWidth:  240
    implicitHeight: 52
    visible: false
    color: "transparent"

    property string iconText:   "󰕾"
    property string titleText:  "Volume"
    property real   levelValue: 50
    property bool   isMuted:    false

    Timer {
        id: hideTimer
        interval: 2200
        repeat: false
        onTriggered: osdRoot.visible = false
    }

    function showOsd(icon, title, val, muted) {
        iconText   = icon;
        titleText  = title;
        levelValue = Math.max(0, Math.min(100, val));
        isMuted    = muted || false;
        visible    = true;
        hideTimer.restart();
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.11, 0.11, 0.14, 0.96)
        radius: 26
        border.color: Qt.rgba(1, 1, 1, 0.13)
        border.width: 1

        // Subtle drop shadow effect via layered rects
        layer.enabled: true

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 0
            anchors.bottomMargin: 0
            spacing: 12

            // Icon
            Text {
                text: osdRoot.isMuted ? "󰖁" : osdRoot.iconText
                font.family: Theme.fontIcon
                font.pixelSize: 20
                color: osdRoot.isMuted ? "#ff6b6b" : ColorService.accent
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignHCenter
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // Progress track
            Rectangle {
                Layout.fillWidth: true
                implicitWidth: 140
                height: 6; radius: 3
                color: Qt.rgba(1, 1, 1, 0.15)

                Rectangle {
                    width: Math.max(radius * 2, parent.width * (osdRoot.levelValue / 100.0))
                    height: parent.height; radius: parent.radius
                    color: osdRoot.isMuted ? "#ff6b6b" : ColorService.accent
                    Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation  { duration: 150 } }
                }
            }

            // Value text
            Text {
                text: osdRoot.isMuted ? "Muted" : (Math.round(osdRoot.levelValue) + "%")
                color: Qt.rgba(1, 1, 1, 0.9)
                font.family: Theme.fontMain
                font.pixelSize: 12
                font.bold: true
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }
}
