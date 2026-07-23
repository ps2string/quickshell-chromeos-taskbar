import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import ".."
import "../services"

// ChromeOS-style bottom shelf / taskbar
// Layout: [Launcher] [Workspaces] | [Pins + Open Apps (centered)] | [Status Pill → Quick Settings]

PanelWindow {
    id: barWindow

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Normal
    WlrLayershell.exclusiveZone: 48

    anchors { bottom: true; left: true; right: true }
    implicitHeight: 48

    signal toggleLauncher()
    signal toggleQuickSettings()
    signal requestShelfContextMenu(var itemData, real posX)

    function openShelfContextMenu(item, posX) {
        requestShelfContextMenu(item, posX);
    }

    // --- Time / Date ---
    property string currentTime: "00:00"
    property string currentDate: "Jan 1"
    property string currentDay:  "Mon"
    property bool   showSeconds: false

    function getAppId(toplevel) {
        if (!toplevel) return "";
        // Hyprland toplevels expose class via lastIpcObject
        if (toplevel.lastIpcObject) {
            let cls = toplevel.lastIpcObject["class"];
            if (cls && typeof cls === "string" && cls.length > 0) return cls;
            let iCls = toplevel.lastIpcObject["initialClass"];
            if (iCls && typeof iCls === "string" && iCls.length > 0) return iCls;
        }
        // Wayland ToplevelManager toplevels expose appId directly
        if (toplevel.appId && typeof toplevel.appId === "string" && toplevel.appId.length > 0)
            return toplevel.appId;
        if (toplevel.title && typeof toplevel.title === "string")
            return toplevel.title;
        return "";
    }

    function getAllToplevels() {
        let result = [];
        let seen = new Set();

        // Use Hyprland.toplevels (always available on Hyprland)
        if (typeof Hyprland !== "undefined" && Hyprland && Hyprland.toplevels && Hyprland.toplevels.values) {
            let vals = Hyprland.toplevels.values;
            for (let i = 0; i < vals.length; i++) {
                let t = vals[i];
                if (t) {
                    let id = barWindow.getAppId(t).toLowerCase();
                    if (id && !seen.has(id)) seen.add(id);
                    result.push(t);
                }
            }
        }

        return result;
    }

    function findMatchingToplevel(pinData) {
        if (!pinData) return null;
        let appId = (pinData.appId || "").toLowerCase().replace(/\.desktop$/, "");
        let exec = (pinData.exec || "").toLowerCase();
        let name = (pinData.name || "").toLowerCase();
        let icon = (pinData.icon || "").toLowerCase();

        if (typeof Hyprland === "undefined" || !Hyprland || !Hyprland.toplevels || !Hyprland.toplevels.values)
            return null;

        let vals = Hyprland.toplevels.values;
        for (let i = 0; i < vals.length; i++) {
            let t = vals[i];
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
        command: ["date", "+%H:%M|%b %d|%a"]
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

    // --- Wallpaper watcher via Hyprland IPC ---
    // Fires matugen whenever Hyprland dispatches a wallpaper change event
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "wallpaper") {
                let data = event.parse(2);
                // data[1] is the wallpaper path
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

    // ===== SHELF BACKGROUND =====
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(
            Qt.darker(ColorService.bgBase, 1.1).r,
            Qt.darker(ColorService.bgBase, 1.1).g,
            Qt.darker(ColorService.bgBase, 1.1).b,
            0.92
        )
        layer.enabled: true

        Behavior on color { ColorAnimation { duration: 400 } }
    }

    // Subtle top border line (ChromeOS shelf shadow)
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(1, 1, 1, 0.08)
    }

    Item {
        id: barContent
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6

        // =========================================================
        // LEFT: Launcher (Google/ChromeOS circles icon)
        // =========================================================
        Item {
            id: leftSection
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: launcherBtn.width + workspaceRow.width + 8
            height: parent.height

            // Launcher button — ChromeOS "circle" launcher
            Rectangle {
                id: launcherBtn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 36; height: 36; radius: 18
                color: launcherMouse.containsMouse
                    ? Qt.rgba(ColorService.accent.r, ColorService.accent.g, ColorService.accent.b, 0.18)
                    : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }

                // Google-style 4-dot grid (ChromeOS launcher icon)
                Grid {
                    anchors.centerIn: parent
                    columns: 2
                    spacing: 4
                    Repeater {
                        model: [ColorService.danger, ColorService.success, ColorService.accent, ColorService.textSecondary]
                        Rectangle {
                            width: 7; height: 7; radius: 2
                            color: modelData
                            Behavior on color { ColorAnimation { duration: 400 } }
                        }
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

            // Workspace pill indicators (ChromeOS overview button style)
            Row {
                id: workspaceRow
                anchors.left: launcherBtn.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    // Show workspaces 1-9 that exist in Hyprland
                    model: {
                        let ids = [];
                        if (Hyprland.workspaces && Hyprland.workspaces.values) {
                            let ws = Hyprland.workspaces.values;
                            for (let i = 0; i < ws.length; i++) {
                                let w = ws[i];
                                if (w && w.id > 0 && w.id <= 9) ids.push(w.id);
                            }
                        }
                        // Ensure at least workspaces 1-3 always show
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

                        width: isActive ? 28 : 22
                        height: 22
                        radius: 11
                        anchors.verticalCenter: parent.verticalCenter

                        color: isActive
                            ? Qt.rgba(ColorService.accent.r, ColorService.accent.g, ColorService.accent.b, 0.25)
                            : (wsMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05))
                        border.color: isActive ? ColorService.accent : Qt.rgba(1, 1, 1, 0.1)
                        border.width: isActive ? 1.5 : 1

                        Behavior on width        { NumberAnimation { duration: 180 } }
                        Behavior on color        { ColorAnimation  { duration: 180 } }
                        Behavior on border.color { ColorAnimation  { duration: 180 } }

                        Text {
                            anchors.centerIn: parent
                            text: wsId
                            color: isActive ? ColorService.accent : ColorService.textSecondary
                            font.family: Theme.fontMain
                            font.pixelSize: 11
                            font.bold: isActive
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

        // =========================================================
        // CENTER: Pinned apps + open windows dock (perfectly centered)
        // =========================================================
        Row {
            id: centerDock
            anchors.centerIn: parent
            spacing: 4

            // --- Pinned apps ---
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

            // --- Separator (pipe) between pinned apps and unpinned running processes ---
            Item {
                id: dockPipeSeparator
                // Show separator when there are unpinned running apps
                // We check Hyprland.toplevels.values and count unpinned ones
                property bool hasUnpinned: {
                    if (typeof Hyprland === "undefined" || !Hyprland.toplevels || !Hyprland.toplevels.values)
                        return false;
                    let _dep = Hyprland.activeToplevel; // reactive dependency
                    let vals = Hyprland.toplevels.values;
                    for (let i = 0; i < vals.length; i++) {
                        if (vals[i] && !barWindow.isToplevelPinned(vals[i])) return true;
                    }
                    return false;
                }
                visible: PinsService.pins.length > 0 && hasUnpinned
                width: 12
                height: 44
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.centerIn: parent
                    width: 2
                    height: 20
                    radius: 1
                    color: Qt.rgba(1, 1, 1, 0.25)

                    Behavior on color { ColorAnimation { duration: 400 } }
                }
            }

            // --- Unpinned open windows (running processes) ---
            // Use Hyprland.toplevels directly as model for reactivity.
            // Filter pinned apps via delegate's `visible` property.
            Repeater {
                id: unpinnedApps
                model: (typeof Hyprland !== "undefined" && Hyprland.toplevels) ? Hyprland.toplevels : null
                delegate: ShelfItem {
                    id: unpinnedItem
                    required property var modelData
                    // Only show windows that aren't already pinned
                    visible: modelData && !barWindow.isToplevelPinned(modelData)
                    width: visible ? 44 : 0
                    pinData: null
                    openToplevel: modelData
                    onRequestContextMenu: (mx, my) => {
                        let mapped = unpinnedItem.mapToItem(barContent, mx, my);
                        barWindow.openShelfContextMenu(unpinnedItem, mapped.x);
                    }
                }
            }
        }

        // =========================================================
        // RIGHT: Status pill → Quick Settings
        // =========================================================
        Rectangle {
            id: statusPill
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 36
            width: statusRow.implicitWidth + 20
            radius: Theme.radiusPill
            color: statusMouse.containsMouse
                ? Qt.rgba(ColorService.bgHover.r, ColorService.bgHover.g, ColorService.bgHover.b, 1.0)
                : Qt.rgba(ColorService.bgSurface.r, ColorService.bgSurface.g, ColorService.bgSurface.b, 1.0)

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                id: statusRow
                anchors.centerIn: parent
                spacing: 10

                // Network icon
                Text {
                    text: SystemService.wifiConnected ? "󰤨" : "󰤭"
                    font.family: Theme.fontIcon
                    font.pixelSize: 14
                    color: ColorService.textPrimary
                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                // Volume icon
                Text {
                    text: SystemService.isMuted ? "󰖁" : (SystemService.volume > 60 ? "󰕾" : (SystemService.volume > 0 ? "󰖀" : "󰕿"))
                    font.family: Theme.fontIcon
                    font.pixelSize: 14
                    color: ColorService.textPrimary
                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                // Battery
                RowLayout {
                    spacing: 3
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
                        color: SystemService.batteryLevel <= 15 ? ColorService.danger : ColorService.textPrimary
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                    Text {
                        text: SystemService.batteryLevel + "%"
                        color: ColorService.textPrimary
                        font.family: Theme.fontMain
                        font.pixelSize: 12
                        font.bold: true
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                }

                // Dot separator
                Rectangle {
                    width: 3; height: 3; radius: 2
                    color: ColorService.textSecondary
                }

                // Clock
                Column {
                    spacing: 0
                    Text {
                        text: barWindow.currentTime
                        color: ColorService.textPrimary
                        font.family: Theme.fontMain
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                    Text {
                        text: barWindow.currentDate
                        color: ColorService.textSecondary
                        font.family: Theme.fontMain
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        Behavior on color { ColorAnimation { duration: 400 } }
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
