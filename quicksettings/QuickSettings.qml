import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../services"

// ChromeOS-style Quick Settings panel with Wi-Fi and Bluetooth detail sub-pages
PopupWindow {
    id: qsRoot

    implicitWidth:  360
    implicitHeight: 400
    visible: false
    color: "transparent"
    grabFocus: true

    property string currentView: "main" // "main", "wifi", "bluetooth"
    property string selectedWifiSsid: ""
    property string wifiPasswordInput: ""

    // Connection result toast
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
        id: toastTimer
        interval: 4000
        repeat: false
        onTriggered: qsRoot._toastVisible = false
    }

    onVisibleChanged: {
        if (visible) {
            currentView = "main";
            selectedWifiSsid = "";
            wifiPasswordInput = "";
            SystemService.refresh();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(ColorService.bgBase.r, ColorService.bgBase.g, ColorService.bgBase.b, 0.96)
        radius: Theme.radiusLarge
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 400 } }

        // =========================================================
        // VIEW 1: MAIN QUICK SETTINGS PANEL
        // =========================================================
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            visible: qsRoot.currentView === "main"

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // User avatar
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

                Column {
                    spacing: 2
                    Text {
                        text: {
                            let u = Quickshell.env("USER") || "User";
                            return u.charAt(0).toUpperCase() + u.slice(1);
                        }
                        color: ColorService.textPrimary
                        font.family: Theme.fontMain
                        font.pixelSize: 14
                        font.bold: true
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                    Text {
                        text: SystemService.wifiConnected ? SystemService.wifiSsid : "Wi-Fi disconnected"
                        color: ColorService.textSecondary
                        font.family: Theme.fontMain
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                }

                Item { Layout.fillWidth: true }

                // Power action buttons
                Row {
                    spacing: 6
                    QsIconBtn { icon: "󰌾"; tooltip: "Lock screen"; onAct: SystemService.lockScreen() }
                    QsIconBtn { icon: "󰜉"; tooltip: "Restart"; onAct: SystemService.reboot() }
                    QsIconBtn { icon: "󰐥"; tooltip: "Power off"; danger: true; onAct: SystemService.powerOff() }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

            // Toggle tiles (2-col grid with detail expanders like ChromeOS)
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                // Wi-Fi tile
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

                // Bluetooth tile
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

                // Do Not Disturb tile
                QsSimpleTile {
                    icon: SystemService.dndActive ? "󰂛" : "󰖔"
                    label: "Do Not Disturb"
                    sublabel: SystemService.dndActive ? "On" : "Off"
                    active: SystemService.dndActive
                    onTap: SystemService.toggleDnd()
                }

                // Night Light tile
                QsSimpleTile {
                    icon: SystemService.nightLightOn ? "󰛮" : "󰛩"
                    label: "Night Light"
                    sublabel: SystemService.nightLightOn ? "On" : "Off"
                    active: SystemService.nightLightOn
                    onTap: SystemService.toggleNightLight()
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

            // Sliders
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                QsSlider {
                    iconOn:  "󰕾"
                    iconOff: "󰖁"
                    muted:   SystemService.isMuted
                    value:   SystemService.volume
                    onSliderMoved: (v) => SystemService.setVolume(v)
                    onIconClicked: SystemService.toggleMute()
                }

                QsSlider {
                    iconOn:  "󰃠"
                    iconOff: "󰃞"
                    muted:   false
                    value:   SystemService.brightness
                    onSliderMoved: (v) => SystemService.setBrightness(v)
                    onIconClicked: {}
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

            // Battery row
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

            Item { Layout.fillHeight: true }
        }

        // =========================================================
        // VIEW 2: WI-FI NETWORKS SUB-PAGE
        // =========================================================
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10
            visible: qsRoot.currentView === "wifi"

            // Header bar
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

                // Wi-Fi On/Off switch (controls radio, not connection)
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

            // Status bar: scanning / connecting / empty
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
                            return "Connecting to " + SystemService.wifiNetworks.length > 0 ? "network…" : "network…";
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

            // Networks List
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: parent.width
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
                                ? Qt.rgba(ColorService.accentDim.r, ColorService.accentDim.g, ColorService.accentDim.b, 0.4)
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
                                            ? Qt.rgba(ColorService.accent.r, ColorService.accent.g, ColorService.accent.b, 0.4)
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
                                        // Open network — connect immediately
                                        SystemService.connectWifi(net.ssid, "");
                                    } else {
                                        // Secured network — toggle password field
                                        qsRoot.selectedWifiSsid = (qsRoot.selectedWifiSsid === net.ssid) ? "" : net.ssid;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =========================================================
        // VIEW 3: BLUETOOTH DEVICES SUB-PAGE
        // =========================================================
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10
            visible: qsRoot.currentView === "bluetooth"

            // Header bar
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

                // Bluetooth On/Off switch
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

            // Scanning indicator
            Text {
                visible: SystemService.isScanningBt
                text: "Scanning bluetooth devices..."
                color: ColorService.accent
                font.family: Theme.fontMain
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
            }

            // Devices List
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: parent.width
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
                                ? Qt.rgba(ColorService.accentDim.r, ColorService.accentDim.g, ColorService.accentDim.b, 0.4)
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
                                    color: dev.connected ? Qt.rgba(ColorService.danger.r, ColorService.danger.g, ColorService.danger.b, 0.2) : ColorService.bgElevated
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
    }

    // ---- Helper components ----

    // Icon button
    component QsIconBtn: Rectangle {
        id: iconBtn
        property string icon: ""
        property string tooltip: ""
        property bool danger: false
        signal act()

        width: 32; height: 32; radius: 16
        color: ibArea.containsMouse
            ? (danger ? ColorService.danger : ColorService.bgHover)
            : (danger ? Qt.rgba(ColorService.danger.r, ColorService.danger.g, ColorService.danger.b, 0.25) : ColorService.bgSurface)
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

    // ChromeOS Expandable Tile (Wi-Fi / Bluetooth with toggle icon AND sub-page arrow)
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
        color: active
            ? Qt.rgba(ColorService.accentDim.r, ColorService.accentDim.g, ColorService.accentDim.b, 1.0)
            : ColorService.bgSurface
        border.color: active ? ColorService.accent : "transparent"
        border.width: active ? 1.5 : 0
        Behavior on color        { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            // Left icon button (toggles power on/off)
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

            // Label & Sublabel (opens detail view)
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

            // Arrow button ❯ (opens detail view)
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

    // Simple Toggle Tile (DND / Night Light)
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
        color: active
            ? Qt.rgba(ColorService.accentDim.r, ColorService.accentDim.g, ColorService.accentDim.b, 1.0)
            : ColorService.bgSurface
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

    // Slider Row Component with direct MouseArea drag tracking
    component QsSlider: RowLayout {
        id: slRow
        property string iconOn: ""
        property string iconOff: ""
        property bool muted: false
        property real value: 50
        signal sliderMoved(real v)
        signal iconClicked()

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

        // Custom Slider Track & Handle
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
    }
}
