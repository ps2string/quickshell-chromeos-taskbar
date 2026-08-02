import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import Quickshell.Services.SystemTray
import Quickshell.Widgets 
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../services"

PopupWindow {
    id: qsRoot

    implicitWidth: 380
    implicitHeight: currentView === "main"
        ? (mainLayout.implicitHeight + 36)
        : 420

    property bool isOpen: false

    color: "transparent"

    signal openSettings()

    property string currentView: "main"
    property string selectedWifiSsid: ""
    property string wifiPasswordInput: ""

    property bool   powerExpanded: false

    property string _toastMsg: ""
    property bool   _toastOk:  true
    property bool   _toastVisible: false

    Connections {
        target: SystemService
        function onWifiConnectResult(success, message) {
            qsRoot._toastOk     = success;
            qsRoot._toastMsg    = message;
            qsRoot._toastVisible = true;
            toastTimer.restart();
        }
    }

    Process {
        id: powerProc
    }

    function executePowerAction(action) {
        qsRoot.powerExpanded = false;
        qsRoot.isOpen = false;
        switch(action) {
            case "poweroff":  powerProc.command = ["systemctl", "poweroff"]; break;
            case "reboot":    powerProc.command = ["systemctl", "reboot"];   break;
            case "suspend":   powerProc.command = ["systemctl", "suspend"];  break;
            case "lock":      powerProc.command = ["hyprlock"];              break;
            case "logout":    powerProc.command = ["hyprctl", "dispatch", "exit"]; break;
            default: return;
        }
        powerProc.running = true;
    }

    onVisibleChanged: {
        if (!qsRoot.visible && qsRoot.isOpen) {
            qsRoot.isOpen = false;
        }
    }

    onIsOpenChanged: {
        if (isOpen) {
            qsRoot.visible = true;
            currentView = "main";
            selectedWifiSsid = "";
            wifiPasswordInput = "";
            powerExpanded = false;
            SystemService.refresh();
        } else {
            qsRoot.visible = false;
        }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        
        opacity: qsRoot.isOpen ? 1.0 : 0.0
        Behavior on opacity { 
            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } 
        }

        transform: Translate {
            y: qsRoot.isOpen ? 0 : 24
            Behavior on y { 
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic } 
            }
        }

        color: Qt.alpha(ColorService.bgBase, 0.95)
        radius: 28
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 400 } }

        ColumnLayout {
            id: mainLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            spacing: 14
            visible: qsRoot.currentView === "main"

            RowLayout {
                z: 99
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    height: 40
                    implicitWidth: userRow.implicitWidth + 24
                    radius: 20
                    color: ColorService.bgElevated
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    RowLayout {
                        id: userRow
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 26; height: 26; radius: 13
                            color: ColorService.accent
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: Theme.fontIcon
                                font.pixelSize: 13
                                color: ColorService.bgBase
                            }
                        }

                        Text {
                            text: {
                                let u = Quickshell.env("USER") || "User";
                                return u.charAt(0).toUpperCase() + u.slice(1);
                            }
                            color: ColorService.textPrimary
                            font.family: Theme.fontMain
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                QsIconBtn {
                    icon: "󰒓"
                    tooltip: "Settings"
                    onAct: qsRoot.openSettings()
                }

                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: qsRoot.powerExpanded
                        ? Qt.alpha("#f28b82", 0.25)
                        : (pwrBtnMa.containsMouse ? Qt.alpha("#f28b82", 0.18) : Qt.alpha("#f28b82", 0.1))
                    border.color: qsRoot.powerExpanded ? Qt.alpha("#f28b82", 0.6) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰐥"
                        font.family: Theme.fontIcon
                        font.pixelSize: 18
                        color: "#f28b82"
                    }

                    MouseArea {
                        id: pwrBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: qsRoot.powerExpanded = !qsRoot.powerExpanded
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                QsExpandableTile {
                    icon: SystemService.wifiEnabled ? (SystemService.wifiConnected ? "󰤨" : "󰤭") : "󰤮"
                    label: "Wi-Fi"
                    sublabel: SystemService.wifiConnected ? SystemService.wifiSsid : (SystemService.wifiEnabled ? "On" : "Off")
                    active: SystemService.wifiEnabled
                    onToggle: SystemService.toggleWifi()
                    onOpenDetail: {
                        qsRoot.currentView = "wifi";
                        SystemService.scanWifi();
                    }
                }

                QsExpandableTile {
                    icon: SystemService.bluetoothOn ? "󰂯" : "󰂲"
                    label: "Bluetooth"
                    sublabel: SystemService.bluetoothOn ? "On" : "Off"
                    active: SystemService.bluetoothOn
                    onToggle: SystemService.toggleBluetooth()
                    onOpenDetail: {
                        qsRoot.currentView = "bluetooth";
                        SystemService.scanBluetooth();
                    }
                }

                QsSimpleTile {
                    icon: SystemService.dndActive ? "󰂛" : "󰖔"
                    label: "Do Not Disturb"
                    sublabel: SystemService.dndActive ? "On" : "Off"
                    active: SystemService.dndActive
                    onTap: SystemService.toggleDnd()
                }

                QsSimpleTile {
                    icon: SystemService.nightLightOn ? "󰛮" : "󰛩"
                    label: "Night Light"
                    sublabel: SystemService.nightLightOn ? "On" : "Off"
                    active: SystemService.nightLightOn
                    onTap: SystemService.toggleNightLight()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                QsSlider {
                    iconOn:  "󰕾"
                    iconOff: "󰖁"
                    muted:   SystemService.isMuted
                    value:   SystemService.volume
                    hasDetail: true
                    onSliderMoved: (v) => SystemService.setVolume(v)
                    onIconClicked: SystemService.toggleMute()
                    onDetailClicked: qsRoot.currentView = "audio"
                }

                QsSlider {
                    iconOn:  "󰃠"
                    iconOff: "󰃞"
                    muted:   false
                    value:   SystemService.brightness
                    hasDetail: false
                    onSliderMoved: (v) => SystemService.setBrightness(v)
                    onIconClicked: {}
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: 24
                color: ColorService.bgElevated
                border.color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: SystemService.isCharging ? "󰂄" : (SystemService.batteryLevel > 20 ? "󰁹" : "󰁻")
                        font.family: Theme.fontIcon
                        font.pixelSize: 18
                        color: SystemService.batteryLevel <= 15 ? ColorService.danger : ColorService.accent
                    }

                    Text {
                        text: {
                            let statusText = SystemService.batteryLevel + "%";
                            let timeEstimate = SystemService.batteryTime ? SystemService.batteryTime : "";
                            
                            if (SystemService.isCharging) {
                                statusText += timeEstimate ? (" • Full in " + timeEstimate) : " • Charging";
                            } else {
                                statusText += timeEstimate ? (" • " + timeEstimate + " left") : "";
                            }
                            
                            return statusText;
                        }
                        color: ColorService.textPrimary
                        font.family: Theme.fontMain
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 80; height: 8; radius: 4
                        color: Qt.rgba(1, 1, 1, 0.1)
                        clip: true
                        Rectangle {
                            width: Math.max(4, parent.width * (SystemService.batteryLevel / 100))
                            height: parent.height; radius: parent.radius
                            color: SystemService.batteryLevel <= 15 ? ColorService.danger
                                 : SystemService.isCharging ? ColorService.success
                                 : ColorService.accent
                            Behavior on width { NumberAnimation { duration: 300 } }
                        }
                    }
                }
            }

			            Rectangle {
			                id: backgroundAppsMenu
			                Layout.fillWidth: true
			                height: 64
			                radius: 20
			                color: ColorService.bgElevated
			                border.color: Qt.rgba(1, 1, 1, 0.06)
			                border.width: 1
			
			                RowLayout {
			                    anchors.fill: parent
			                    anchors.margins: 10
			                    spacing: 12
			
			                    Rectangle {
			                        width: 44; height: 44; radius: 22
			                        color: SystemTray.items.values.length > 0 ? Qt.alpha(ColorService.accent, 0.15) : Qt.rgba(1, 1, 1, 0.08)
			                        Text {
			                            anchors.centerIn: parent
			                            text: "󰍜"
			                            font.family: Theme.fontIcon
			                            font.pixelSize: 20
			                            color: SystemTray.items.values.length > 0 ? ColorService.accent : ColorService.textPrimary
			                        }
			                    }
			
			                    Column {
			                        Layout.fillWidth: true
			                        spacing: 2
			                        Text {
			                            text: "Background Apps"
			                            color: ColorService.textPrimary
			                            font.family: Theme.fontMain
			                            font.bold: true
			                            font.pixelSize: 13
			                        }
			                        Text {
			                            text: SystemTray.items.values.length > 0 
			                                  ? SystemTray.items.values.length + " active app(s)"
			                                  : "No background apps"
			                            color: ColorService.textSecondary
			                            font.family: Theme.fontMain
			                            font.pixelSize: 11
			                        }
			                    }
			
			                    Rectangle {
			                        width: 32; height: 44; radius: 16
			                        color: trayArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
			                        Text {
			                            anchors.centerIn: parent
			                            text: "❯"
			                            font.family: Theme.fontMain
			                            font.pixelSize: 11
			                            font.bold: true
			                            color: ColorService.textSecondary
			                        }
			                        MouseArea {
			                            id: trayArea
			                            anchors.fill: parent
			                            hoverEnabled: true
			                            cursorShape: Qt.PointingHandCursor
			                            onClicked: qsRoot.currentView = "tray" 
			                        }
			                    }
			                }
			            }

            Rectangle {
                id: notifHistoryMenu
                Layout.fillWidth: true
                height: 64
                radius: 20
                color: ColorService.bgElevated
                border.color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    Rectangle {
                        width: 44; height: 44; radius: 22
                        color: NotificationService.trackedNotifications.values.length > 0 ? Qt.alpha(ColorService.accent, 0.15) : Qt.rgba(1, 1, 1, 0.08)
                        Text {
                            anchors.centerIn: parent
                            text: "󰎟" 
                            font.family: Theme.fontIcon
                            font.pixelSize: 20
                            color: NotificationService.trackedNotifications.values.length > 0 ? ColorService.accent : ColorService.textPrimary
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Notification History"
                            color: ColorService.textPrimary
                            font.family: Theme.fontMain
                            font.bold: true
                            font.pixelSize: 13
                        }
                        Text {
                            text: NotificationService.trackedNotifications.values.length > 0 
                                  ? NotificationService.trackedNotifications.values.length + " active notification(s)"
                                  : "No new notifications"
                            color: ColorService.textSecondary
                            font.family: Theme.fontMain
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        width: 32; height: 44; radius: 16
                        color: nhArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "❯"
                            font.family: Theme.fontMain
                            font.pixelSize: 11
                            font.bold: true
                            color: ColorService.textSecondary
                        }
                        MouseArea {
                            id: nhArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: qsRoot.currentView = "notifications"
                        }
                    }
                }
            }

        }

        MouseArea {
            anchors.fill: parent
            visible: qsRoot.powerExpanded
            z: 199
            onClicked: qsRoot.powerExpanded = false
        }

        Rectangle {
            id: powerOverlay
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            anchors.topMargin: 60
            z: 200

            implicitHeight: powerOverlayContent.implicitHeight + 24

            radius: 22
            color: Qt.rgba(
                ColorService.bgBase.r * 0.6 + 0.35,
                ColorService.bgBase.g * 0.6 + 0.05,
                ColorService.bgBase.b * 0.6 + 0.05,
                0.97
            )
            border.color: Qt.alpha("#f28b82", 0.45)
            border.width: 1.5

            layer.enabled: true

            opacity: qsRoot.powerExpanded ? 1.0 : 0.0
            scale: qsRoot.powerExpanded ? 1.0 : 0.92
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on scale  { NumberAnimation { duration: 220; easing.type: Easing.OutBack  } }

            ColumnLayout {
                id: powerOverlayContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: Qt.alpha("#f28b82", 0.18)
                        Text {
                            anchors.centerIn: parent
                            text: "󰐥"
                            font.family: Theme.fontIcon
                            font.pixelSize: 16
                            color: "#f28b82"
                        }
                    }

                    Text {
                        text: "Power"
                        font.family: Theme.fontMain
                        font.pixelSize: 15
                        font.bold: true
                        color: "#f28b82"
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: closePwrOverlayMa.containsMouse
                            ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: Theme.fontIcon
                            font.pixelSize: 12
                            color: ColorService.textSecondary
                        }
                        MouseArea {
                            id: closePwrOverlayMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: qsRoot.powerExpanded = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.alpha("#f28b82", 0.2)
                }

                Row {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { icon: "󰐥", label: "Power Off",  action: "poweroff", color: "#f28b82" },
                            { icon: "󰑓", label: "Restart",    action: "reboot",   color: "#fdd663" },
                            { icon: "󰒲", label: "Suspend",    action: "suspend",  color: "#78d9ec" },
                            { icon: "󰌾", label: "Lock",       action: "lock",     color: "#81c995" },
                            { icon: "󰍃", label: "Log Out",    action: "logout",   color: "#ff9d6f" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            width: (powerOverlay.width - 32 - 8 * 4) / 5
                            height: width + 6
                            radius: 16
                            color: pwrOverlayActMa.containsMouse
                                ? Qt.alpha(modelData.color, 0.32)
                                : Qt.alpha(modelData.color, 0.12)
                            border.color: pwrOverlayActMa.containsMouse
                                ? Qt.alpha(modelData.color, 0.7)
                                : Qt.alpha(modelData.color, 0.3)
                            border.width: 1.5

                            Behavior on color { ColorAnimation { duration: 130 } }
                            Behavior on border.color { ColorAnimation { duration: 130 } }
                            scale: pwrOverlayActMa.pressed ? 0.93 : (pwrOverlayActMa.containsMouse ? 1.05 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.icon
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 24
                                    color: modelData.color
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    font.family: Theme.fontMain
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: ColorService.textPrimary
                                    horizontalAlignment: Text.AlignHCenter
                                    width: parent.parent.width - 6
                                    wrapMode: Text.WordWrap
                                }
                            }

                            MouseArea {
                                id: pwrOverlayActMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: qsRoot.executePowerAction(modelData.action)
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            visible: qsRoot.currentView === "wifi"

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                QsIconBtn {
                    icon: "󰅁"
                    tooltip: "Back"
                    onAct: qsRoot.currentView = "main"
                }

                Text {
                    text: "Internet"
                    color: ColorService.textPrimary
                    font.family: Theme.fontMain
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }

                QsIconBtn {
                    icon: "󰑐"
                    tooltip: "Rescan"
                    onAct: SystemService.scanWifi()
                }

                Rectangle {
                    width: 48; height: 26; radius: 13
                    color: SystemService.wifiEnabled ? ColorService.accent : ColorService.bgElevated
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Rectangle {
                        width: 20; height: 20; radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        x: SystemService.wifiEnabled ? 24 : 3
                        color: ColorService.bgBase
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemService.toggleWifi()
                    }
                }
            }
            
            ScrollView {
                id: wifiScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: wifiScroll.width
                    spacing: 6

                    Repeater {
                        model: SystemService.wifiNetworks
                        delegate: Rectangle {
                            id: netItem
                            property var net: modelData
                            Layout.fillWidth: true
                            implicitHeight: isSelected ? 92 : 52
                            radius: 16
                            color: net.inUse
                                ? Qt.alpha(ColorService.accent, 0.2)
                                : (netArea.containsMouse ? ColorService.bgHover : ColorService.bgElevated)
                            border.color: net.inUse ? ColorService.accent : "transparent"
                            border.width: net.inUse ? 1.5 : 0
                            Behavior on implicitHeight { NumberAnimation { duration: 150 } }

                            property bool isSelected: qsRoot.selectedWifiSsid === net.ssid

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Text {
                                        text: net.signal > 70 ? "󰤨" : (net.signal > 40 ? "󰤥" : (net.signal > 20 ? "󰤢" : "󰤟"))
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 18
                                        color: net.inUse ? ColorService.accent : ColorService.textPrimary
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            width: parent.width
                                            text: net.ssid
                                            color: ColorService.textPrimary
                                            font.family: Theme.fontMain
                                            font.pixelSize: 13
                                            font.bold: net.inUse
                                            elide: Text.ElideMiddle 
                                        }
                                        Text {
                                            text: net.inUse ? "Connected" : (net.security.length > 0 ? net.security : "Open")
                                            color: net.inUse ? ColorService.accent : ColorService.textSecondary
                                            font.family: Theme.fontMain
                                            font.pixelSize: 11
                                        }
                                    }
                                }

                                RowLayout {
                                    visible: netItem.isSelected && !net.inUse
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 32; radius: 12
                                        color: ColorService.bgSurface
                                        border.color: ColorService.accent
                                        border.width: 1

                                        TextInput {
                                            id: passInput
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            echoMode: TextInput.Password
                                            font.family: Theme.fontMain
                                            font.pixelSize: 12
                                            color: ColorService.textPrimary
                                            focus: netItem.isSelected
                                            onTextChanged: qsRoot.wifiPasswordInput = text
                                            onAccepted: {
                                                if (!SystemService.isConnectingWifi) {
                                                    SystemService.connectWifi(net.ssid, text);
                                                    qsRoot.selectedWifiSsid = "";
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 72; height: 32; radius: 16
                                        color: SystemService.isConnectingWifi
                                            ? Qt.alpha(ColorService.accent, 0.4)
                                            : ColorService.accent
                                        Text {
                                            anchors.centerIn: parent
                                            text: SystemService.isConnectingWifi ? "…" : "Connect"
                                            color: ColorService.bgBase
                                            font.family: Theme.fontMain
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: SystemService.isConnectingWifi ? Qt.WaitCursor : Qt.PointingHandCursor
                                            enabled: !SystemService.isConnectingWifi
                                            onClicked: {
                                                SystemService.connectWifi(net.ssid, passInput.text);
                                                qsRoot.selectedWifiSsid = "";
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: netArea
                                anchors.fill: parent
                                anchors.bottomMargin: netItem.isSelected ? 40 : 0
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (net.inUse) return;
                                    if (net.security.length === 0) {
                                        SystemService.connectWifi(net.ssid, "");
                                    } else {
                                        qsRoot.selectedWifiSsid = (qsRoot.selectedWifiSsid === net.ssid) ? "" : net.ssid;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            visible: qsRoot.currentView === "bluetooth"
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                QsIconBtn {
                    icon: "󰅁"
                    tooltip: "Back"
                    onAct: qsRoot.currentView = "main"
                }

                Text {
                    text: "Bluetooth"
                    color: ColorService.textPrimary
                    font.family: Theme.fontMain
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }
            }
            
            ScrollView {
                id: btScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: btScroll.width
                    spacing: 6

                    Repeater {
                        model: SystemService.bluetoothDevices
                        delegate: Rectangle {
                            id: devItem
                            property var dev: modelData
                            Layout.fillWidth: true
                            height: 50
                            radius: 16
                            color: dev.connected ? Qt.alpha(ColorService.accent, 0.2) : ColorService.bgElevated
                            border.color: dev.connected ? ColorService.accent : "transparent"
                            border.width: dev.connected ? 1.5 : 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Text {
                                    text: "󰂯"
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 18
                                    color: dev.connected ? ColorService.accent : ColorService.textPrimary
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        width: parent.width
                                        text: dev.name
                                        color: ColorService.textPrimary
                                        font.family: Theme.fontMain
                                        font.pixelSize: 13
                                        font.bold: dev.connected
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            visible: qsRoot.currentView === "audio"
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                QsIconBtn {
                    icon: "󰅁"
                    tooltip: "Back"
                    onAct: qsRoot.currentView = "main"
                }

                Text {
                    text: "Sound Settings"
                    color: ColorService.textPrimary
                    font.family: Theme.fontMain
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }
            }

            ScrollView {
                id: audioScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: audioScroll.width
                    spacing: 6

                    Repeater {
                        model: Pipewire.nodes
                        
                        delegate: Rectangle {
                            id: audioItem
                            property var node: modelData
                            property bool isValidAudio: node && node.audio !== null
                            property bool isApp: isValidAudio && node.isStream
                            property bool isOutput: isValidAudio && node.isSink && !node.isStream
                            property bool isInput: isValidAudio && !node.isSink && !node.isStream

                            visible: isValidAudio
                            Layout.fillWidth: true
                            height: isValidAudio ? 54 : 0
                            Layout.preferredHeight: isValidAudio ? 54 : 0
                            radius: 16
                            
                            property bool isDefault: (isOutput && Pipewire.defaultAudioSink === node) || 
                                                     (isInput && Pipewire.defaultAudioSource === node)

                            color: isDefault ? Qt.alpha(ColorService.accent, 0.2) : ColorService.bgElevated
                            border.color: isDefault ? ColorService.accent : "transparent"
                            border.width: isDefault ? 1.5 : 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10
                                visible: isValidAudio

                                Text {
                                    text: isApp ? "󰎆" : (isOutput ? "󰓃" : "󰍬")
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 18
                                    color: isDefault ? ColorService.accent : ColorService.textPrimary
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        width: parent.width
                                        text: {
                                            if (!node) return "";
                                            if (isApp && node.properties) {
                                                return node.properties["media.name"] || node.properties["application.name"] || node.name;
                                            }
                                            return node.description || node.name || "Unknown Device";
                                        }
                                        color: ColorService.textPrimary
                                        font.family: Theme.fontMain
                                        font.pixelSize: 13
                                        font.bold: isDefault || isApp
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: isApp ? "Application" : (isOutput ? "Output Device" : "Input Device")
                                        color: isDefault ? ColorService.accent : ColorService.textSecondary
                                        font.family: Theme.fontMain
                                        font.pixelSize: 11
                                    }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: isApp ? Qt.ArrowCursor : Qt.PointingHandCursor
                                enabled: isValidAudio && !isApp
                                onClicked: {
                                    if (isOutput) {
                                        Pipewire.preferredDefaultAudioSink = node;
                                    } else if (isInput) {
                                        Pipewire.preferredDefaultAudioSource = node;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            visible: qsRoot.currentView === "notifications"

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                QsIconBtn {
                    icon: "󰅁"
                    tooltip: "Back"
                    onAct: qsRoot.currentView = "main"
                }

                Text {
                    text: "Notifications"
                    color: ColorService.textPrimary
                    font.family: Theme.fontMain
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    visible: NotificationService.trackedNotifications.values.length > 0
                    text: "Clear all"
                    color: ColorService.accent
                    font.family: Theme.fontMain
                    font.pixelSize: 12
                    font.bold: true
                
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let items = NotificationService.trackedNotifications.values;
                            for (let i = items.length - 1; i >= 0; i--) {
                                items[i].tracked = false; 
                            }
                        }
                    }
                }
            }

            ScrollView {
                id: notifScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: notifList
                    width: notifScroll.width
                    height: notifScroll.height
                    
                    model: NotificationService.trackedNotifications
                    spacing: 8
                    
                    delegate: Rectangle {
                        id: notifDelegate
                        
                        property var notif: modelData

                        width: ListView.view.width
                        implicitHeight: contentCol.implicitHeight + 24
                        radius: 16
                        color: ColorService.bgElevated
                        border.color: Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1

                        ColumnLayout {
                            id: contentCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "󰎟" 
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 16
                                    color: ColorService.accent
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: (notif && notif.appName) ? notif.appName : "System"
                                    color: ColorService.textPrimary
                                    font.family: Theme.fontMain
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: closeArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08)
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        color: closeArea.containsMouse ? ColorService.textPrimary : ColorService.textSecondary
                                        font.family: Theme.fontMain
                                        font.pixelSize: 13
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: closeArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (notif) {
                                                notif.tracked = false; 
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: notif && notif.summary && notif.summary.length > 0
                                text: notif ? notif.summary : ""
                                color: ColorService.textPrimary
                                font.family: Theme.fontMain
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }

                            Text {
                                visible: notif && notif.body && notif.body.length > 0
                                text: notif ? notif.body : ""
                                color: ColorService.textSecondary
                                font.family: Theme.fontMain
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                textFormat: Text.RichText
                            }
                        }
                    }
                }
            }
            
            Text {
                visible: NotificationService.trackedNotifications.values.length === 0
                text: "No notifications right now."
                color: ColorService.textSecondary
                font.family: Theme.fontMain
                font.pixelSize: 13
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
            }
        }
    }

	        ColumnLayout {
	            anchors.fill: parent
	            anchors.margins: 18
	            spacing: 12
	            visible: qsRoot.currentView === "tray"
	
	            RowLayout {
	                Layout.fillWidth: true
	                spacing: 10
	
	                QsIconBtn {
	                    icon: "󰅁"
	                    tooltip: "Back"
	                    onAct: qsRoot.currentView = "main"
	                }
	
	                Text {
	                    text: "Background Apps"
	                    color: ColorService.textPrimary
	                    font.family: Theme.fontMain
	                    font.pixelSize: 16
	                    font.bold: true
	                    Layout.fillWidth: true
	                }
	            }
	
	            ScrollView {
	                id: trayScroll
	                Layout.fillWidth: true
	                Layout.fillHeight: true
	                clip: true
	
	                ColumnLayout {
	                    width: trayScroll.width
	                    spacing: 6
	
	                    Repeater {
	                        model: SystemTray.items
	
	                        delegate: Rectangle {
	                            id: trayItemDelegate
	                            required property var modelData
	
	                            Layout.fillWidth: true
	                            height: 54
	                            radius: 16
	                            color: itemMouseArea.containsMouse ? ColorService.bgHover : ColorService.bgElevated
	                            border.color: "transparent"
	                            Behavior on color { ColorAnimation { duration: 150 } }
	
	                            RowLayout {
	                                anchors.fill: parent
	                                anchors.margins: 10
	                                spacing: 12
	
	                                IconImage {
	                                    width: 24
	                                    height: 24
	                                    source: modelData.icon
	                                }
	
	                                Column {
	                                    Layout.fillWidth: true
	                                    spacing: 2
	                                    Text {
	                                        width: parent.width
	                                        text: modelData.title !== "" ? modelData.title : (modelData.id !== "" ? modelData.id : "Unknown App")
	                                        color: ColorService.textPrimary
	                                        font.family: Theme.fontMain
	                                        font.pixelSize: 13
	                                        font.bold: true
	                                        elide: Text.ElideRight
	                                    }
	                                    Text {
	                                        text: modelData.tooltipTitle !== "" ? modelData.tooltipTitle : "Background Service"
	                                        color: ColorService.textSecondary
	                                        font.family: Theme.fontMain
	                                        font.pixelSize: 11
	                                        elide: Text.ElideRight
	                                    }
	                                }
	                            }
	
	                            QsMenuAnchor {
	                                id: menuAnchor
	                                menu: modelData.menu
	                                anchor {
	                                    edges: Edges.Right
	                                    gravity: Edges.Bottom | Edges.Right
	                                }
	                            }
	
	                            MouseArea {
	                                id: itemMouseArea
	                                anchors.fill: parent
	                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
	                                hoverEnabled: true
	                                cursorShape: Qt.PointingHandCursor
	
	                                onClicked: mouse => {
	                                    if (mouse.button === Qt.RightButton) {
	                                        if (modelData.menu) {
	                                            
	                                            menuAnchor.anchor.item = trayItemDelegate;
	                                            menuAnchor.open();
	                                        } else if (modelData.hasMenu) {
	                                            let win = qsRoot.Window.window;
	                                            if (win) {
	                                                let pos = itemMouseArea.mapToItem(null, mouse.x, mouse.y);
	                                                modelData.display(win, pos.x, pos.y);
	                                            }
	                                        } else {
	                                            modelData.secondaryActivate();
	                                        }
	                                    } else if (mouse.button === Qt.LeftButton) {
	                                        modelData.activate();
	                                        qsRoot.isOpen = false; 
	                                    } else if (mouse.button === Qt.MiddleButton) {
	                                        modelData.secondaryActivate();
	                                    }
	                                }
	                            }
	                        }
	                    }
	                }
	            }
	
	            Text {
	                visible: SystemTray.items.values.length === 0
	                text: "No apps running in the background."
	                color: ColorService.textSecondary
	                font.family: Theme.fontMain
	                font.pixelSize: 13
	                Layout.alignment: Qt.AlignHCenter
	                Layout.topMargin: 20
	            }
	        }


    component QsIconBtn: Rectangle {
        id: iconBtn
        property string icon: ""
        property string tooltip: ""
        property bool danger: false
        signal act()

        width: 32; height: 32; radius: 16
        color: ibArea.containsMouse
            ? (danger ? ColorService.danger : Qt.alpha(ColorService.accent, 0.3))
            : (danger ? Qt.alpha(ColorService.danger, 0.2) : Qt.alpha(ColorService.accent, 0.15))
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: iconBtn.icon
            font.family: Theme.fontIcon
            font.pixelSize: 14
            color: danger ? (ibArea.containsMouse ? ColorService.bgBase : ColorService.danger) : ColorService.textPrimary
        }
        ToolTip.text: iconBtn.tooltip
        ToolTip.visible: ibArea.containsMouse && iconBtn.tooltip.length > 0
        ToolTip.delay: 500
        MouseArea {
            id: ibArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: iconBtn.act()
        }
    }

    component QsExpandableTile: Rectangle {
        id: tile
        property string icon: ""
        property string label: ""
        property string sublabel: ""
        property bool active: false
        signal toggle()
        signal openDetail()

        Layout.fillWidth: true
        height: 64
        radius: 20
        color: active ? ColorService.accent : ColorService.bgElevated
        Behavior on color { ColorAnimation { duration: 200 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            Rectangle {
                width: 44; height: 44; radius: 22
                color: tile.active ? Qt.rgba(0, 0, 0, 0.15) : Qt.rgba(1, 1, 1, 0.08)
                Text {
                    anchors.centerIn: parent
                    text: tile.icon
                    font.family: Theme.fontIcon
                    font.pixelSize: 20
                    color: tile.active ? ColorService.bgBase : ColorService.textPrimary
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tile.toggle()
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: tile.label
                    color: tile.active ? ColorService.bgBase : ColorService.textPrimary
                    font.family: Theme.fontMain
                    font.bold: true
                    font.pixelSize: 13
                }
                Text {
                    text: tile.sublabel
                    width: parent.width
                    color: tile.active ? Qt.alpha(ColorService.bgBase, 0.8) : ColorService.textSecondary
                    font.family: Theme.fontMain
                    font.pixelSize: 11
                    elide: Text.ElideMiddle 
                }
            }

            Rectangle {
                width: 32; height: 44; radius: 16
                color: detailArea.containsMouse ? (tile.active ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "❯"
                    font.family: Theme.fontMain
                    font.pixelSize: 11
                    font.bold: true
                    color: tile.active ? ColorService.bgBase : ColorService.textSecondary
                }
                MouseArea {
                    id: detailArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tile.openDetail()
                }
            }
        }
    }

    component QsSimpleTile: Rectangle {
        id: tile
        property string icon: ""
        property string label: ""
        property string sublabel: ""
        property bool active: false
        signal tap()

        Layout.fillWidth: true
        height: 64
        radius: 20
        color: active ? ColorService.accent : ColorService.bgElevated
        Behavior on color { ColorAnimation { duration: 200 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Rectangle {
                width: 44; height: 44; radius: 22
                color: tile.active ? Qt.rgba(0, 0, 0, 0.15) : Qt.rgba(1, 1, 1, 0.08)
                Text {
                    anchors.centerIn: parent
                    text: tile.icon
                    font.family: Theme.fontIcon
                    font.pixelSize: 20
                    color: tile.active ? ColorService.bgBase : ColorService.textPrimary
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: tile.label
                    color: tile.active ? ColorService.bgBase : ColorService.textPrimary
                    font.family: Theme.fontMain
                    font.bold: true
                    font.pixelSize: 13
                }
                Text {
                    text: tile.sublabel
                    width: parent.width
                    color: tile.active ? Qt.alpha(ColorService.bgBase, 0.8) : ColorService.textSecondary
                    font.family: Theme.fontMain
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.tap()
        }
    }

    component QsSlider: Rectangle {
        id: slRow
        property string iconOn: ""
        property string iconOff: ""
        property bool muted: false
        property real value: 50
        property bool hasDetail: false 
        signal sliderMoved(real v)
        signal iconClicked()
        signal detailClicked() 

        Layout.fillWidth: true
        height: 48
        radius: 24
        color: ColorService.bgElevated
        clip: true

        Rectangle {
            id: filledTrack
            height: parent.height
            radius: parent.radius
            width: Math.max(parent.height, Math.min(parent.width, parent.width * (slRow.value / 100.0)))
            color: slRow.muted ? ColorService.textSecondary : ColorService.accent
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Text {
                text: slRow.muted ? slRow.iconOff : slRow.iconOn
                font.family: Theme.fontIcon
                font.pixelSize: 18
                color: (slRow.value > 15) ? ColorService.bgBase : ColorService.textPrimary
                Behavior on color { ColorAnimation { duration: 200 } }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: slRow.iconClicked()
                }
            }

            Item {
                id: track
                Layout.fillWidth: true
                height: parent.height

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

                    function calculateAndEmit(mouseX) {
                        let pct = Math.max(0, Math.min(100, Math.round((mouseX / track.width) * 100)));
                        slRow.sliderMoved(pct);
                    }

                    onPressed: (mouse) => calculateAndEmit(mouse.x)
                    onPositionChanged: (mouse) => {
                        if (pressed) calculateAndEmit(mouse.x);
                    }
                }
            }

            Text {
                text: Math.round(slRow.value) + "%"
                color: (slRow.value > 85) ? ColorService.bgBase : ColorService.textPrimary
                font.family: Theme.fontMain
                font.pixelSize: 12
                font.bold: true
            }

            Text {
                visible: slRow.hasDetail
                text: "❯"
                font.family: Theme.fontMain
                font.pixelSize: 11
                font.bold: true
                color: (slRow.value > 92) ? ColorService.bgBase : ColorService.textSecondary
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: slRow.detailClicked()
                }
            }
        }
    }
}
