import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import ".."
import "../services"
import "../components"

PanelWindow {
    id: barWindow

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Normal
    WlrLayershell.exclusiveZone: 64

    anchors { bottom: true; left: true; right: true }
    implicitHeight: 64

    signal toggleLauncher()
    signal toggleQuickSettings()
    signal requestShelfContextMenu(var itemData, real posX)

    function openShelfContextMenu(item, posX) {
        requestShelfContextMenu(item, posX);
    }
    property string currentTime: "00:00"
    property string currentDate: "Jan 1"
    property string currentDay:  "Mon"
    property bool   showSeconds: false

    function getAppId(toplevel) {
            if (!toplevel) return "";
            
            if (toplevel.wayland && toplevel.wayland.appId) return toplevel.wayland.appId;
    
            if (toplevel.lastIpcObject) {
                let cls = toplevel.lastIpcObject["class"];
                if (cls && typeof cls === "string" && cls.length > 0) return cls;
                let iCls = toplevel.lastIpcObject["initialClass"];
                if (iCls && typeof iCls === "string" && iCls.length > 0) return iCls;
            }
            
            if (toplevel.appId && typeof toplevel.appId === "string" && toplevel.appId.length > 0)
                return toplevel.appId;
            if (toplevel.title && typeof toplevel.title === "string")
                return toplevel.title;
                
            return "";
        }

    function isWindowValidAndVisible(t) {
        if (!t) return false;
        if (t.lastIpcObject) {
            if (t.lastIpcObject.mapped === false) return false;
            if (t.lastIpcObject.hidden === true) return false;
        }
        let aid = barWindow.getAppId(t);
        if (!aid || aid.length === 0) return false;
        return true;
    }

    function getUnpinnedApps() {
        if (typeof Hyprland === "undefined" || !Hyprland.toplevels || !Hyprland.toplevels.values)
            return [];

        let vals = Hyprland.toplevels.values;
        let result = [];
        let seenAppIds = new Set();

        for (let i = 0; i < vals.length; i++) {
            let t = vals[i];
            if (!isWindowValidAndVisible(t)) continue;

            let appId = barWindow.getAppId(t).toLowerCase();
            if (!barWindow.isToplevelPinned(t) && !seenAppIds.has(appId)) {
                seenAppIds.add(appId);
                result.push(t);
            }
        }
        return result;
    }

    function findMatchingToplevel(pinData) {
        if (!pinData) return null;
        let appId = (pinData.appId || "").toLowerCase().replace(/\.desktop$/, "");
        let exec = (pinData.exec || "").toLowerCase();
        let icon = (pinData.icon || "").toLowerCase();

        if (typeof Hyprland === "undefined" || !Hyprland || !Hyprland.toplevels || !Hyprland.toplevels.values)
            return null;

        let vals = Hyprland.toplevels.values;
        for (let i = 0; i < vals.length; i++) {
            let t = vals[i];
            if (!isWindowValidAndVisible(t)) continue;

            let tApp = getAppId(t).toLowerCase();
            if (!tApp) continue;

            if (tApp === appId || tApp === icon || tApp === exec) return t;
            if (appId.length > 0 && (appId.includes(tApp) || tApp.includes(appId))) return t;
            if (icon.length > 0 && (icon.includes(tApp) || tApp.includes(icon))) return t;
            if (exec.length > 0 && exec.split(" ")[0].includes(tApp)) return t;
        }
        return null;
    }

    function isToplevelPinned(toplevel) {
        if (!toplevel) return false;
        let tApp = getAppId(toplevel).toLowerCase();
        if (!tApp) return false;
        return PinsService.pins.some(p => {
            let appId = (p.appId || "").toLowerCase().replace(/\.desktop$/, "");
            let exec = (p.exec || "").toLowerCase();
            let icon = (p.icon || "").toLowerCase();
            return tApp === appId || tApp === icon || tApp === exec ||
                   (appId.length > 0 && (appId.includes(tApp) || tApp.includes(appId))) ||
                   (icon.length > 0 && (icon.includes(tApp) || tApp.includes(icon))) ||
                   (exec.length > 0 && exec.split(" ")[0].includes(tApp));
        });
    }

    Process {
        id: clockProc
        command: ["date", "+%r|%B %D|%A"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split("|");
                if (parts.length >= 3) {
                    barWindow.currentTime = parts[0];
                    barWindow.currentDate = parts[1];
                    barWindow.currentDay  = parts[2];
                }
            }
        }
    }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: clockProc.running = true }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "wallpaper") {
                let data = event.parse(2);
                let wp = data.length >= 2 ? data[1] : "";
                if (wp.length > 0) {
                    wallpaperThemeProc.command = [
                        "bash",
                        Qt.resolvedUrl("../scripts/wallpaper-theme.sh").toString().replace("file://", ""),
                        wp
                    ];
                    wallpaperThemeProc.running = true;
                }
            }
        }
    }

    Process { id: wallpaperThemeProc }

    color: "transparent"

    Item {
        id: barContent
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 8

        // =========================================================
        // LEFT PILL: LAUNCHER & WORKSPACES
        // =========================================================
        Rectangle {
            id: leftSection
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: leftLayout.implicitWidth + 20
            height: 48
            radius: 24
            color: Qt.rgba(ColorService.bgElevated.r, ColorService.bgElevated.g, ColorService.bgElevated.b, 0.82)
            border.color: Qt.alpha(ColorService.accent, 0.18)
            border.width: 1.5

            RowLayout {
                id: leftLayout
                anchors.centerIn: parent
                spacing: 10

                Rectangle {
                    id: launcherBtn
                    width: 38; height: 38; radius: 19
                    color: launcherMouse.containsMouse 
                        ? Qt.alpha(ColorService.accent, 0.25) 
                        : Qt.alpha(ColorService.accent, 0.1)
                    scale: launcherMouse.containsMouse ? 1.08 : 1.0

                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                    Item {
                        anchors.centerIn: parent
                        width: 20; height: 20

                        Rectangle {
                            anchors.centerIn: parent
                            width: 18; height: 18; radius: 9
                            color: "transparent"
                            border.color: ColorService.accent
                            border.width: 2.5
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 8; height: 8; radius: 4
                            color: ColorService.accent
                        }
                    }

                    MouseArea {
                        id: launcherMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: barWindow.toggleLauncher()
                    }
                }

                Row {
                    id: workspaceRow
                    spacing: 6

                    Repeater {
                        model: {
                            let ids = [];
                            if (Hyprland.workspaces && Hyprland.workspaces.values) {
                                let ws = Hyprland.workspaces.values;
                                for (let i = 0; i < ws.length; i++) {
                                    let w = ws[i];
                                    if (w && w.id > 0 && w.id <= 9) ids.push(w.id);
                                }
                            }
                            for (let i = 1; i <= 3; i++) {
                                if (!ids.includes(i)) ids.push(i);
                            }
                            ids.sort((a, b) => a - b);
                            return ids;
                        }

                        delegate: Rectangle {
                            id: wsBadge
                            property int wsId: modelData
                            property bool isActive: {
                                let fw = Hyprland.focusedWorkspace;
                                return fw ? fw.id === wsId : false;
                            }

                            implicitWidth: isActive ? wsText.implicitWidth + 24 : 32
                            height: 32
                            radius: 16
                            anchors.verticalCenter: parent.verticalCenter

                            color: isActive 
                                ? ColorService.accent 
                                : (wsMouse.containsMouse ? Qt.alpha(ColorService.accent, 0.15) : "transparent")

                            scale: wsMouse.containsMouse && !isActive ? 1.08 : 1.0

                            Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            Behavior on color         { ColorAnimation  { duration: 180 } }
                            Behavior on scale         { NumberAnimation { duration: 180 } }

                            Text {
                                id: wsText
                                anchors.centerIn: parent
                                text: isActive ? "Desk " + wsId : wsId.toString()
                                color: isActive ? ColorService.bgBase : ColorService.textPrimary
                                font.family: Theme.fontMain
                                font.pixelSize: 12
                                font.bold: true
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }

                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch("workspace " + wsId)
                            }
                        }
                    }
                }
            }
        }

        // =========================================================
        // CENTER PILL: EXPRESSIVE APP DOCK
        // =========================================================
        Rectangle {
            id: centerSection
            anchors.centerIn: parent
            width: centerDock.implicitWidth + 24
            height: 52
            radius: 26
            color: Qt.rgba(ColorService.bgElevated.r, ColorService.bgElevated.g, ColorService.bgElevated.b, 0.82)
            border.color: Qt.alpha(ColorService.accent, 0.18)
            border.width: 1.5

            Row {
                id: centerDock
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    model: PinsService.pins
                    delegate: ShelfItem {
                        id: pinnedItem
                        pinData: modelData
                        openToplevel: barWindow.findMatchingToplevel(modelData)
                        onRequestContextMenu: (mx, my) => {
                            let mapped = pinnedItem.mapToItem(barContent, mx, my);
                            barWindow.openShelfContextMenu(pinnedItem, mapped.x);
                        }
                    }
                }

                Item {
                    id: dockPipeSeparator
                    property bool hasUnpinned: barWindow.getUnpinnedApps().length > 0
                    visible: PinsService.pins.length > 0 && hasUnpinned
                    width: 12
                    height: 40
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.centerIn: parent
                        width: 3
                        height: 20
                        radius: 1.5
                        color: Qt.alpha(ColorService.accent, 0.3)
                    }
                }

                Repeater {
                    id: unpinnedApps
                    model: barWindow.getUnpinnedApps()
                    delegate: ShelfItem {
                        id: unpinnedItem
                        required property var modelData
                        pinData: null
                        openToplevel: modelData
                        onRequestContextMenu: (mx, my) => {
                            let mapped = unpinnedItem.mapToItem(barContent, mx, my);
                            barWindow.openShelfContextMenu(unpinnedItem, mapped.x);
                        }
                    }
                }
            }
        }

        // =========================================================
        // RIGHT PILL: SYSTEM STATUS & CLOCK
        // =========================================================
        RowLayout {
            id: rightSection
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            SystemTray {
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                id: statusPill
                Layout.alignment: Qt.AlignVCenter
                height: 48
                implicitWidth: statusRow.implicitWidth + 24
                radius: 24
                color: statusMouse.containsMouse 
                    ? Qt.alpha(ColorService.bgHover, 0.95) 
                    : Qt.rgba(ColorService.bgElevated.r, ColorService.bgElevated.g, ColorService.bgElevated.b, 0.82)
                border.color: Qt.alpha(ColorService.accent, 0.18)
                border.width: 1.5

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 10

                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: SystemService.wifiConnected ? "󰤨" : "󰤭"
                            font.family: Theme.fontIcon
                            font.pixelSize: 15
                            color: SystemService.wifiConnected ? ColorService.accent : ColorService.textSecondary
                        }

                        Text {
                            text: SystemService.isMuted ? "󰖁" : (SystemService.volume > 60 ? "󰕾" : (SystemService.volume > 0 ? "󰖀" : "󰕿"))
                            font.family: Theme.fontIcon
                            font.pixelSize: 15
                            color: SystemService.isMuted ? ColorService.danger : ColorService.accent
                        }

                        Rectangle {
                            implicitWidth: batRow.implicitWidth + 12
                            height: 26
                            radius: 13
                            color: Qt.alpha(ColorService.accent, 0.15)
                            Layout.alignment: Qt.AlignVCenter

                            RowLayout {
                                id: batRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: {
                                        let lvl = SystemService.batteryLevel;
                                        if (SystemService.isCharging) return "󰂄";
                                        if (lvl > 90) return "󰁹";
                                        if (lvl > 70) return "󰂀";
                                        if (lvl > 50) return "󰁾";
                                        if (lvl > 30) return "󰁼";
                                        if (lvl > 15) return "󰁺";
                                        return "󰁻";
                                    }
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 14
                                    color: SystemService.batteryLevel <= 15 ? ColorService.danger : ColorService.accent
                                }
                                Text {
                                    text: SystemService.batteryLevel + "%"
                                    color: ColorService.textPrimary
                                    font.family: Theme.fontMain
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 2; height: 18; radius: 1
                        color: Qt.alpha(ColorService.accent, 0.2)
                        Layout.alignment: Qt.AlignVCenter
                    }

                    RowLayout {
                        spacing: 6
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: barWindow.currentTime
                            color: ColorService.textPrimary
                            font.family: Theme.fontMain
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            text: barWindow.currentDate
                            color: ColorService.textSecondary
                            font.family: Theme.fontMain
                            font.pixelSize: 11
                        }
                    }
                }

                MouseArea {
                    id: statusMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.toggleQuickSettings()
                }
            }
        }
    }
}
