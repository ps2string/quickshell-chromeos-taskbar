import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../services"

PopupWindow {
    id: qsRoot

    implicitWidth:  360
    implicitHeight: currentView === "main" ? (mainLayout.implicitHeight + 32) : 400
    
    property bool isOpen: false
    
    color: "transparent"
    grabFocus: true

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

       Timer {
           id: closeTimer
           interval: 250 
           onTriggered: qsRoot.visible = false
       }
   
       onVisibleChanged: {
           if (!qsRoot.visible && qsRoot.isOpen) {
               qsRoot.isOpen = false;
               closeTimer.stop();
           }
       }
   
       onIsOpenChanged: {
           if (isOpen) {

               closeTimer.stop();
               qsRoot.visible = true;
               
               currentView = "main";
               selectedWifiSsid = "";
               wifiPasswordInput = "";
               powerExpanded = false;
               SystemService.refresh();
           } else {
               if (qsRoot.visible) {
                   closeTimer.restart();
               }
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
            y: qsRoot.isOpen ? 0 : 20
            Behavior on y { 
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic } 
            }
        }


        color: Qt.alpha(ColorService.bgBase, 0.96)
        radius: Theme.radiusLarge
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 400 } }

        ColumnLayout {
            id: mainLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 12
            visible: qsRoot.currentView === "main"

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 36; height: 36; radius: 18
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: ColorService.accent }
                        GradientStop { position: 1.0; color: ColorService.success }
                    }
                    Behavior on gradient { ColorAnimation { duration: 400 } }
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: Theme.fontIcon
                        font.pixelSize: 16
                        color: ColorService.bgBase
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: {
                            let u = Quickshell.env("USER") || "User";
                            return u.charAt(0).toUpperCase() + u.slice(1);
                        }
                        color: ColorService.textPrimary
                        font.family: Theme.fontMain
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: SystemService.wifiConnected ? SystemService.wifiSsid : "Wi-Fi disconnected"
                        color: ColorService.textSecondary
                        font.family: Theme.fontMain
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                }

                Rectangle {
                    id: powerMenu
                    Layout.alignment: Qt.AlignRight 
                    implicitWidth: qsRoot.powerExpanded ? 112 : 32 
                    height: 32
                    radius: 16
                    color: qsRoot.powerExpanded ? ColorService.bgElevated : "transparent"
                    border.color: qsRoot.powerExpanded ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                    border.width: qsRoot.powerExpanded ? 1 : 0
                    clip: true

                    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }

                    RowLayout {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        QsIconBtn {
                            visible: qsRoot.powerExpanded
                            icon: "󰍃"
                            tooltip: "Log out"
                            onAct: {
                                qsRoot.powerExpanded = false;
                                if (typeof SystemService.logout === "function") {
                                    SystemService.logout();
                                } else {
                                    SystemService.lockScreen();
                                }
                            }
                        }

                        QsIconBtn {
                            visible: qsRoot.powerExpanded
                            icon: "󰜉"
                            tooltip: "Restart"
                            onAct: {
                                qsRoot.powerExpanded = false;
                                SystemService.reboot();
                            }
                        }

                        QsIconBtn {
                            icon: "󰐥"
                            tooltip: qsRoot.powerExpanded ? "Power off" : "Power menu"
                            danger: true
                            onAct: {
                                if (!qsRoot.powerExpanded) {
                                    qsRoot.powerExpanded = true;
                                } else {
                                    SystemService.powerOff();
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

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

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

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

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: SystemService.isCharging ? "󰂄" : (SystemService.batteryLevel > 20 ? "󰁹" : "󰁻")
                    font.family: Theme.fontIcon
                    font.pixelSize: 20
                    color: SystemService.batteryLevel <= 15 ? ColorService.danger : ColorService.textPrimary
                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                Column {
                    spacing: 2
                    Text {
                        text: SystemService.batteryLevel + "% — " + (SystemService.isCharging ? "Charging" : "Battery")
                        color: ColorService.textPrimary
                        font.family: Theme.fontMain
                        font.pixelSize: 13
                        font.bold: true
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                    Rectangle {
                        width: 200; height: 5; radius: 3
                        color: ColorService.bgElevated
                        Rectangle {
                            width: Math.max(6, parent.width * (SystemService.batteryLevel / 100))
                            height: parent.height; radius: parent.radius
                            color: SystemService.batteryLevel <= 15 ? ColorService.danger
                                 : SystemService.isCharging ? ColorService.success
                                 : ColorService.accent
                            Behavior on width { NumberAnimation { duration: 300 } }
                            Behavior on color { ColorAnimation { duration: 400 } }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10
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
                    text: "Wi-Fi Networks"
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
                    width: 44; height: 24; radius: 12
                    color: SystemService.wifiEnabled ? ColorService.accent : ColorService.bgElevated
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Rectangle {
                        width: 18; height: 18; radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        x: SystemService.wifiEnabled ? 22 : 4
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

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

            RowLayout {
                Layout.fillWidth: true
                visible: SystemService.isScanningWifi || SystemService.isConnectingWifi || qsRoot._toastVisible
                spacing: 6

                Text {
                    visible: !qsRoot._toastVisible
                    text: SystemService.isConnectingWifi ? "󰤽" : "󰑐"
                    font.family: Theme.fontIcon
                    font.pixelSize: 13
                    color: ColorService.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: {
                        if (qsRoot._toastVisible)
                            return qsRoot._toastMsg;
                        if (SystemService.isConnectingWifi)
                            return "Connecting to network…";
                        return "Scanning for networks…";
                    }
                    color: qsRoot._toastVisible
                        ? (qsRoot._toastOk ? ColorService.success : ColorService.danger)
                        : ColorService.accent
                    font.family: Theme.fontMain
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            ScrollView {
                id: wifiScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: wifiScroll.width
                    spacing: 4

                    Repeater {
                        model: SystemService.wifiNetworks
                        delegate: Rectangle {
                            id: netItem
                            property var net: modelData
                            Layout.fillWidth: true
                            implicitHeight: isSelected ? 86 : 44
                            radius: 8
                            color: net.inUse
                                ? Qt.alpha(ColorService.accentDim, 0.4)
                                : (netArea.containsMouse ? ColorService.bgHover : ColorService.bgSurface)
                            border.color: net.inUse ? ColorService.accent : "transparent"
                            border.width: net.inUse ? 1 : 0
                            Behavior on implicitHeight { NumberAnimation { duration: 150 } }

                            property bool isSelected: qsRoot.selectedWifiSsid === net.ssid

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

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
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: net.inUse ? "Connected" : (net.security.length > 0 ? net.security : "Open")
                                            color: net.inUse ? ColorService.accent : ColorService.textSecondary
                                            font.family: Theme.fontMain
                                            font.pixelSize: 11
                                        }
                                    }

                                    Text {
                                        visible: net.security.length > 0 && !net.inUse
                                        text: "󰌾"
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 14
                                        color: ColorService.textSecondary
                                    }

                                    Text {
                                        visible: net.inUse
                                        text: "󰄬"
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 16
                                        color: ColorService.accent
                                    }
                                }

                                RowLayout {
                                    visible: netItem.isSelected && !net.inUse
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 30; radius: 6
                                        color: ColorService.bgElevated
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
                                        width: 68; height: 30; radius: 6
                                        color: SystemService.isConnectingWifi
                                            ? Qt.alpha(ColorService.accent, 0.4)
                                            : ColorService.accent
                                        Behavior on color { ColorAnimation { duration: 150 } }
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
                                anchors.bottomMargin: netItem.isSelected ? 36 : 0
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
            anchors.margins: 16
            spacing: 10
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
                    text: "Bluetooth Devices"
                    color: ColorService.textPrimary
                    font.family: Theme.fontMain
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }

                QsIconBtn {
                    icon: "󰑐"
                    tooltip: "Refresh"
                    onAct: SystemService.scanBluetooth()
                }

                Rectangle {
                    width: 44; height: 24; radius: 12
                    color: SystemService.bluetoothOn ? ColorService.accent : ColorService.bgElevated
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Rectangle {
                        width: 18; height: 18; radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        x: SystemService.bluetoothOn ? 22 : 4
                        color: ColorService.bgBase
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemService.toggleBluetooth()
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

            Text {
                visible: SystemService.isScanningBt
                text: "Scanning bluetooth devices..."
                color: ColorService.accent
                font.family: Theme.fontMain
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
            }

            ScrollView {
                id: btScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: btScroll.width
                    spacing: 4

                    Repeater {
                        model: SystemService.bluetoothDevices
                        delegate: Rectangle {
                            id: devItem
                            property var dev: modelData
                            Layout.fillWidth: true
                            height: 44
                            radius: 8
                            color: dev.connected
                                ? Qt.alpha(ColorService.accentDim, 0.4)
                                : (devArea.containsMouse ? ColorService.bgHover : ColorService.bgSurface)
                            border.color: dev.connected ? ColorService.accent : "transparent"
                            border.width: dev.connected ? 1 : 0

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
                                    Text {
                                        text: dev.connected ? "Connected" : dev.mac
                                        color: dev.connected ? ColorService.accent : ColorService.textSecondary
                                        font.family: Theme.fontMain
                                        font.pixelSize: 11
                                    }
                                }

                                Rectangle {
                                    width: 70; height: 26; radius: 6
                                    color: dev.connected ? Qt.alpha(ColorService.danger, 0.2) : ColorService.bgElevated
                                    border.color: dev.connected ? ColorService.danger : Qt.rgba(1,1,1,0.1)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: dev.connected ? "Disconnect" : "Connect"
                                        color: dev.connected ? ColorService.danger : ColorService.textPrimary
                                        font.family: Theme.fontMain
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (dev.connected) {
                                                SystemService.disconnectBt(dev.mac);
                                            } else {
                                                SystemService.connectBt(dev.mac);
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: devArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (dev.connected) {
                                        SystemService.disconnectBt(dev.mac);
                                    } else {
                                        SystemService.connectBt(dev.mac);
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: SystemService.bluetoothDevices.length === 0 && !SystemService.isScanningBt
                        text: SystemService.bluetoothOn ? "No bluetooth devices found." : "Bluetooth is disabled."
                        color: ColorService.textSecondary
                        font.family: Theme.fontMain
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 20
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10
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
                    text: "Audio Devices"
                    color: ColorService.textPrimary
                    font.family: Theme.fontMain
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

            ScrollView {
                id: audioScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: audioScroll.width
                    spacing: 8

                    Text {
                        text: "Output"
                        color: ColorService.accent
                        font.family: Theme.fontMain
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Repeater {
                        model: SystemService.audioOutputs
                        delegate: Rectangle {
                            id: audioOutItem
                            Layout.fillWidth: true
                            implicitWidth: 200
                            height: 44
                            radius: 8
                            color: modelData.inUse
                                ? Qt.alpha(ColorService.accentDim, 0.4)
                                : (outArea.containsMouse ? ColorService.bgHover : ColorService.bgSurface)
                            border.color: modelData.inUse ? ColorService.accent : "transparent"
                            border.width: modelData.inUse ? 1 : 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Text {
                                    text: "󰓃" 
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 18
                                    color: modelData.inUse ? ColorService.accent : ColorService.textPrimary
                                }

                                Column {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: modelData.deviceLabel || SystemService.getNodeLabel(modelData.rawNode)
                                        color: ColorService.textPrimary
                                        font.family: Theme.fontMain
                                        font.pixelSize: 13
                                        font.bold: modelData.inUse
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    visible: modelData.inUse
                                    text: "󰄬" 
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 16
                                    color: ColorService.accent
                                }
                            }

                            MouseArea {
                                id: outArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SystemService.setAudioOutput(modelData)
                            }
                        }
                    }

                    Text {
                        visible: SystemService.audioOutputs.length === 0
                        text: "No output devices found."
                        color: ColorService.textSecondary
                        font.family: Theme.fontMain
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                    }

                    Text {
                        text: "Input"
                        color: ColorService.accent
                        font.family: Theme.fontMain
                        font.pixelSize: 12
                        font.bold: true
                        Layout.topMargin: 8
                    }

                    Repeater {
                        model: SystemService.audioInputs
                        delegate: Rectangle {
                            id: audioInItem
                            Layout.fillWidth: true
                            implicitWidth: 200
                            height: 44
                            radius: 8
                            color: modelData.inUse
                                ? Qt.alpha(ColorService.accentDim, 0.4)
                                : (inArea.containsMouse ? ColorService.bgHover : ColorService.bgSurface)
                            border.color: modelData.inUse ? ColorService.accent : "transparent"
                            border.width: modelData.inUse ? 1 : 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Text {
                                    text: "󰍬" 
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 18
                                    color: modelData.inUse ? ColorService.accent : ColorService.textPrimary
                                }

                                Column {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: modelData.deviceLabel || SystemService.getNodeLabel(modelData.rawNode)
                                        color: ColorService.textPrimary
                                        font.family: Theme.fontMain
                                        font.pixelSize: 13
                                        font.bold: modelData.inUse
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    visible: modelData.inUse
                                    text: "󰄬"
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 16
                                    color: ColorService.accent
                                }
                            }

                            MouseArea {
                                id: inArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SystemService.setAudioInput(modelData)
                            }
                        }
                    }

                    Text {
                        visible: SystemService.audioInputs.length === 0
                        text: "No input devices found."
                        color: ColorService.textSecondary
                        font.family: Theme.fontMain
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 4
                    }
                }
            }
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
            ? (danger ? ColorService.danger : ColorService.bgHover)
            : (danger ? Qt.alpha(ColorService.danger, 0.25) : ColorService.bgSurface)
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: iconBtn.icon
            font.family: Theme.fontIcon
            font.pixelSize: 14
            color: danger ? (ibArea.containsMouse ? ColorService.bgBase : ColorService.danger) : ColorService.textPrimary
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        ToolTip.text: iconBtn.tooltip
        ToolTip.visible: ibArea.containsMouse && iconBtn.tooltip.length > 0
        ToolTip.delay: 600
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
        height: 58
        radius: Theme.radiusMedium
        color: active ? ColorService.accentDim : ColorService.bgSurface
        border.color: active ? ColorService.accent : "transparent"
        border.width: active ? 1.5 : 0
        Behavior on color        { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            Rectangle {
                width: 36; height: 36; radius: 18
                color: toggleArea.containsMouse ? ColorService.bgHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: tile.icon
                    font.family: Theme.fontIcon
                    font.pixelSize: 18
                    color: tile.active ? ColorService.accent : ColorService.textPrimary
                }
                MouseArea {
                    id: toggleArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tile.toggle()
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: tile.label
                    color: ColorService.textPrimary
                    font.family: Theme.fontMain
                    font.bold: true
                    font.pixelSize: 13
                }
                Text {
                    text: tile.sublabel
                    color: ColorService.textSecondary
                    font.family: Theme.fontMain
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            Text {
                text: "❯"
                font.family: Theme.fontMain
                font.pixelSize: 12
                font.bold: true
                color: ColorService.textSecondary
                Layout.rightMargin: 4
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.leftMargin: 44
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.openDetail()
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
        height: 58
        radius: Theme.radiusMedium
        color: active ? ColorService.accentDim : ColorService.bgSurface
        border.color: active ? ColorService.accent : "transparent"
        border.width: active ? 1.5 : 0
        Behavior on color        { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                text: tile.icon
                font.family: Theme.fontIcon
                font.pixelSize: 20
                color: tile.active ? ColorService.accent : ColorService.textPrimary
            }
            Column {
                spacing: 2
                Text {
                    text: tile.label
                    color: ColorService.textPrimary
                    font.family: Theme.fontMain
                    font.bold: true
                    font.pixelSize: 13
                }
                Text {
                    text: tile.sublabel
                    color: ColorService.textSecondary
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

    component QsSlider: RowLayout {
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
        spacing: 10

        Text {
            text: slRow.muted ? slRow.iconOff : slRow.iconOn
            font.family: Theme.fontIcon
            font.pixelSize: 18
            color: slRow.muted ? ColorService.textSecondary : ColorService.textPrimary
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
            implicitWidth: 160
            implicitHeight: 24
            height: 24

            Rectangle {
                id: bgTrack
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 6; radius: 3
                color: ColorService.bgElevated

                Rectangle {
                    width: Math.max(0, Math.min(parent.width, parent.width * (slRow.value / 100.0)))
                    height: parent.height; radius: parent.radius
                    color: slRow.muted ? ColorService.textSecondary : ColorService.accent
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(track.width - width, (track.width - width) * (slRow.value / 100.0)))
                width: 18; height: 18; radius: 9
                color: ColorService.accent
                border.color: Qt.rgba(0,0,0,0.2)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 200 } }
            }

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
            color: ColorService.textSecondary
            font.family: Theme.fontMain
            font.pixelSize: 12
            width: 32
            horizontalAlignment: Text.AlignRight
            Behavior on color { ColorAnimation { duration: 400 } }
        }

        Text {
            visible: slRow.hasDetail
            text: "❯"
            font.family: Theme.fontMain
            font.pixelSize: 12
            font.bold: true
            color: ColorService.textSecondary
            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: slRow.detailClicked()
            }
        }
    }
}
