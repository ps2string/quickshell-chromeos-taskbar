import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import ".."
import "../services"

Item {
    id: root

    property var pinData: null
    property var openToplevel: null

   function getToplevelAppId(t) {
        if (!t) return "";
        
        if (t.wayland && t.wayland.appId) return t.wayland.appId;

        if (t.lastIpcObject) {
            let cls = t.lastIpcObject["class"];
            if (cls && typeof cls === "string" && cls.length > 0) return cls;
            let iCls = t.lastIpcObject["initialClass"];
            if (iCls && typeof iCls === "string" && iCls.length > 0) return iCls;
        }
        if (t.appId && typeof t.appId === "string" && t.appId.length > 0) return t.appId;
        return "";
    }
    function activateWindow() {
            if (!openToplevel) return;
    
            if (openToplevel.wayland && typeof openToplevel.wayland.activate === "function") {
                openToplevel.wayland.activate();
                return;
            }
    
            if (openToplevel.address) {
                let addr = openToplevel.address;
                if (!addr.startsWith("0x")) addr = "0x" + addr;
                Hyprland.dispatch("focuswindow address:" + addr);
                return;
            }
    
            let aid = getToplevelAppId(openToplevel);
            if (aid.length > 0) {
                Hyprland.dispatch("focuswindow class:^(" + aid + ")$");
            }
        }

    property bool isActive:   openToplevel ? openToplevel.activated : false
    property bool isOpen:     openToplevel !== null
    property bool isPinned:   pinData !== null
    property string displayName: {
        if (openToplevel && openToplevel.title) return openToplevel.title;
        if (pinData && pinData.name) return pinData.name;
        let aid = getToplevelAppId(openToplevel);
        if (aid.length > 0) return aid;
        return "App";
    }

    property string resolvedIconPath: {
        let rawId = (pinData && pinData.icon) ? pinData.icon : getToplevelAppId(openToplevel);
        if (!rawId || rawId.length === 0) return "";

        let candidates = [rawId];
        let lower = rawId.toLowerCase();
        
        let desktopEntry = DesktopEntries.heuristicLookup(rawId);
        if (!desktopEntry && rawId !== lower) {
            desktopEntry = DesktopEntries.heuristicLookup(lower);
        }
        
        if (desktopEntry && desktopEntry.icon) {
            candidates.unshift(desktopEntry.icon);
        }

        if (lower !== rawId) candidates.push(lower);

        if (rawId.includes(".")) {
            let lastDot = rawId.split(".").pop();
            candidates.push(lastDot);
            candidates.push(lastDot.toLowerCase());
        }

        if (lower.includes("floorp")) candidates.push("floorp", "ablaze-floorp", "firefox", "browser");
        if (lower.includes("kitty")) candidates.push("kitty", "terminal", "utilities-terminal", "system-run");
        if (lower.includes("nautilus")) candidates.push("org.gnome.Nautilus", "nautilus", "system-file-manager", "folder");
        if (lower.includes("gedit") || lower.includes("texteditor")) candidates.push("org.gnome.TextEditor", "text-editor", "gedit");
        if (lower.includes("settings")) candidates.push("preferences-system", "org.gnome.Settings", "gnome-control-center");
        if (lower.includes("code") || lower.includes("vscodium")) candidates.push("vscode", "vscodium", "com.visualstudio.code");
        if (lower.includes("obsidian")) candidates.push("obsidian");
        if (lower.includes("haruna")) candidates.push("org.kde.haruna", "haruna");
        if (lower.includes("easyeda")) candidates.push("easyeda", "easyeda-pro", "easyeda-pro-desktop");
        if (lower.includes("easyeffects") || lower.includes("easy-effects")) candidates.push("easyeffects", "com.github.wwmm.easyeffects");

        for (let i = 0; i < candidates.length; i++) {
            let p = Quickshell.iconPath(candidates[i], true);
            if (p && p.length > 0) return p;
        }

        return Quickshell.iconPath(rawId, true);
    }

    width: 44; height: 44

    Rectangle {
        id: hoverBg
        anchors.centerIn: parent
        width: 40; height: 40; radius: 14
        color: isActive 
            ? Qt.alpha(ColorService.accent, 0.28) 
            : (itemArea.containsMouse ? Qt.alpha(ColorService.accent, 0.15) : "transparent")

        border.color: isActive ? ColorService.accent : "transparent"
        border.width: isActive ? 1.5 : 0

        scale: itemArea.containsMouse ? 1.12 : 1.0

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    }

    IconImage {
            id: appIcon
            anchors.centerIn: parent
            width: 26; height: 26
            source: root.resolvedIconPath
            smooth: true
            scale: itemArea.containsMouse ? 1.1 : 1.0
   
            visible: status === Image.Ready 
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        }
    
        Rectangle {
            anchors.centerIn: parent
            width: 26; height: 26; radius: 8
            color: ColorService.accentDim
       
            visible: appIcon.status !== Image.Ready 
            
            Text {
                anchors.centerIn: parent
                text: displayName.length > 0 ? displayName[0].toUpperCase() : "?"
                color: ColorService.accent
                font.family: ColorService.fontMain
                font.bold: true
                font.pixelSize: 13
            }
        }

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
            font.family: ColorService.fontMain
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
    
            onPressed: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    root.requestContextMenu(mouse.x, mouse.y);
                    return;
                }
                if (openToplevel) {
                    if (isActive) {
                        Hyprland.dispatch("workspace", "empty");
                    } else {
                        root.activateWindow();
                    }
                } else if (pinData && pinData.exec) {
                    let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                    p.command = ["sh", "-c", pinData.exec];
                    p.running = true;
                }
            }
        }
}
