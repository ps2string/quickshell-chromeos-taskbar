import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io
import ".."
import "../services"

Item {
    id: root

    property var pinData: null 
    property var openToplevel: null
    property int pinIndex: typeof index !== "undefined" ? index : -1

    property bool isActive: openToplevel ? openToplevel.activated : false
    property bool isOpen:   openToplevel !== null
    property bool isPinned: pinData !== null

    function getAppId(t) {
        if (!t) return "";
        if (t.appId && typeof t.appId === "string" && t.appId.length > 0)
            return t.appId;
        if (t.title && typeof t.title === "string" && t.title.length > 0)
            return t.title;
        return "";
    }

    property string displayName: {
        if (pinData && pinData.name) return pinData.name;
        if (openToplevel && openToplevel.title) return openToplevel.title;
        let aid = getAppId(openToplevel);
        if (aid.length > 0) return aid;
        return "App";
    }

    property string _iconKey: {
        let raw = "";
        if (pinData && pinData.icon) raw = pinData.icon;
        else if (pinData && pinData.appId) raw = pinData.appId;
        else raw = getAppId(openToplevel);
        // Strip image://icon/ prefix that may be stored in old pins.json
        if (raw.startsWith("image://icon/")) raw = raw.substring(13);
        return raw;
    }

    property string resolvedIconPath: {
        let rawId = _iconKey;
        if (!rawId || rawId.length === 0) return "";

        let candidates = [rawId];
        let lower = rawId.toLowerCase();

        // 1. Try desktop entry heuristic
        let de = DesktopEntries.heuristicLookup(rawId);
        if (!de && rawId !== lower) de = DesktopEntries.heuristicLookup(lower);
        if (de && de.icon) {
            let deIcon = de.icon;
            if (deIcon.startsWith("image://icon/")) deIcon = deIcon.substring(13);
            candidates.unshift(deIcon);
        }

        if (lower !== rawId) candidates.push(lower);
        if (rawId.includes(".")) {
            let lastPart = rawId.split(".").pop();
            candidates.push(lastPart, lastPart.toLowerCase());
        }

        if (lower.includes("floorp"))       candidates.push("floorp", "ablaze-floorp", "firefox");
        if (lower.includes("kitty"))        candidates.push("kitty", "utilities-terminal", "terminal");
        if (lower.includes("nautilus"))     candidates.push("org.gnome.Nautilus", "nautilus", "folder");
        if (lower.includes("obsidian"))     candidates.push("obsidian", "md.obsidian.Obsidian");
        if (lower.includes("code") || lower.includes("vscodium")) candidates.push("vscode", "vscodium");
        if (lower.includes("haruna"))       candidates.push("org.kde.haruna", "haruna");
        if (lower.includes("easyeffects")) candidates.push("easyeffects", "com.github.wwmm.easyeffects");
        if (lower.includes("discord"))      candidates.push("discord", "com.discordapp.Discord");
        if (lower.includes("steam"))        candidates.push("steam", "com.valvesoftware.Steam");
        if (lower.includes("telegram"))     candidates.push("org.telegram.desktop", "telegram-desktop", "telegram");

        for (let i = 0; i < candidates.length; i++) {
            let p = Quickshell.iconPath(candidates[i], true);
            if (p && p.length > 0) return p;
        }
        return Quickshell.iconPath(rawId, true);
    }

    function activateWindow() {
        if (!openToplevel) return;
        if (typeof openToplevel.activate === "function") {
            openToplevel.activate();
        }
    }

   

function launchApp() {
        let aid = pinData ? pinData.appId : getAppId(openToplevel);
        
        if (aid) {
            let entry = DesktopEntries.heuristicLookup(aid);
            if (entry) {
                entry.execute();
                return;
            }
        }
        
        if (pinData && pinData.exec) {
            let cmd = pinData.exec.trim().replace(/%[uUfFickKdDnNvm]/g, "").trim();
            Quickshell.execDetached({ command: ["sh", "-c", cmd] });
        }
    }

   function togglePin() {
            if (isPinned) {
                PinsService.unpin(pinData.appId);
            } else {
                let aid = getAppId(openToplevel);
                let realExec = aid;
                
                let entry = DesktopEntries.heuristicLookup(aid);
                if (entry && entry.command && entry.command.length > 0) {
                    realExec = entry.command[0];
                }
                
                PinsService.pin(aid, displayName, realExec, resolvedIconPath);
            }
        }

    width: DockSettingsService.dockIconSize + 18; height: DockSettingsService.dockIconSize + 18

    Rectangle {
        id: hoverBg
        anchors.centerIn: parent
        width: DockSettingsService.dockIconSize + 14; height: DockSettingsService.dockIconSize + 14; radius: (DockSettingsService.dockIconSize + 14) / 3
        color: isActive
            ? Qt.alpha(ColorService.accent, 0.28)
            : (itemArea.containsMouse ? Qt.alpha(ColorService.accent, 0.15) : "transparent")
        border.color: isActive ? ColorService.accent : "transparent"
        border.width: isActive ? 1.5 : 0
        scale: itemArea.containsMouse ? 1.12 : 1.0

        Behavior on color  { ColorAnimation  { duration: 180 } }
        Behavior on scale  { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    }

    IconImage {
        id: appIcon
        anchors.centerIn: parent
        width: DockSettingsService.dockIconSize; height: DockSettingsService.dockIconSize
        source: root.resolvedIconPath
        smooth: true
        scale: itemArea.containsMouse ? 1.1 : 1.0
        visible: status === Image.Ready
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    }

    Rectangle {
        anchors.centerIn: parent
        width: DockSettingsService.dockIconSize; height: DockSettingsService.dockIconSize; radius: DockSettingsService.dockIconSize / 3
        color: ColorService.accentDim
        visible: appIcon.status !== Image.Ready

        Text {
            anchors.centerIn: parent
            text: displayName.length > 0 ? displayName[0].toUpperCase() : "?"
            color: ColorService.accent
            font.family: Theme.fontMain
            font.bold: true
            font.pixelSize: 13
        }
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        keys: ["shelfItem"]
        onDropped: (drop) => {
            if (root.pinIndex >= 0 && drop.source && drop.source.pinIndex >= 0 && root.pinIndex !== drop.source.pinIndex) {
                PinsService.reorderPin(drop.source.pinIndex, root.pinIndex);
            }
        }
    }

    Drag.active: itemArea.drag.active
    Drag.source: root
    Drag.keys: ["shelfItem"]
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
        anchors.horizontalCenter: parent.horizontalCenter
        width: isActive ? 16 : (isOpen ? 6 : 0)
        height: 3; radius: 1.5
        color: isActive ? ColorService.accent : Qt.alpha(ColorService.textSecondary, 0.6)
        opacity: isOpen ? 1.0 : 0.0

        Behavior on width   { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
        Behavior on color   { ColorAnimation  { duration: 180 } }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    ToolTip {
        id: tooltip
        text: displayName
        visible: itemArea.containsMouse && displayName.length > 0
        delay: 400
        background: Rectangle {
            color: ColorService.bgElevated
            radius: 8
            border.color: Qt.alpha(ColorService.accent, 0.2)
            border.width: 1
        }
        contentItem: Text {
            text: tooltip.text
            color: ColorService.textPrimary
            font.family: Theme.fontMain
            font.pixelSize: 11
            font.bold: true
        }
    }

    signal requestContextMenu(real mouseX, real mouseY)

    MouseArea {
        id: itemArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        drag.target: isPinned ? root : null
        drag.axis: Drag.XAxis
        drag.minimumX: -root.x
        drag.threshold: 8

        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.requestContextMenu(mouse.x, mouse.y);
                mouse.accepted = true;
                return;
            }
            
            if (mouse.button === Qt.LeftButton) {
                if (openToplevel) {
                    root.activateWindow();
                } else {
                    root.launchApp();
                }
            }
        }

        onReleased: {
            if (root.Drag.active) {
                root.Drag.drop();
                root.x = 0;
                root.y = 0;
            }
        }
    }
}
