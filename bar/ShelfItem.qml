import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import ".."
import "../services"

// A single item on the ChromeOS shelf.
// Handles both pinned-only apps (no window) and open windows.
// Shows tooltip, active indicator dot, and right-click context menu.

Item {
    id: root

    // pinData: { appId, name, exec, icon } or null if unpinned open window
    property var pinData: null
    // openToplevel: ToplevelHandle or null
    property var openToplevel: null
    function getToplevelAppId(t) {
        if (!t) return "";
        // Hyprland toplevels: class is in lastIpcObject
        if (t.lastIpcObject) {
            let cls = t.lastIpcObject["class"];
            if (cls && typeof cls === "string" && cls.length > 0) return cls;
            let iCls = t.lastIpcObject["initialClass"];
            if (iCls && typeof iCls === "string" && iCls.length > 0) return iCls;
        }
        // Wayland ToplevelManager toplevels
        if (t.appId && typeof t.appId === "string" && t.appId.length > 0) return t.appId;
        return "";
    }

    function activateWindow() {
        if (!openToplevel) return;
        if (typeof openToplevel.activate === "function") {
            openToplevel.activate();
        } else if (openToplevel.lastIpcObject && openToplevel.lastIpcObject.address) {
            Hyprland.dispatch("focuswindow address:" + openToplevel.lastIpcObject.address);
        } else {
            let aid = getToplevelAppId(openToplevel);
            if (aid.length > 0) Hyprland.dispatch("focuswindow " + aid);
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
        let rawId = (pinData && pinData.icon) ? pinData.icon
                  : getToplevelAppId(openToplevel);
        if (!rawId || rawId.length === 0) return "";

        let candidates = [rawId];
        let lower = rawId.toLowerCase();
        if (lower !== rawId) candidates.push(lower);

        if (rawId.includes(".")) {
            let lastDot = rawId.split(".").pop();
            candidates.push(lastDot);
            candidates.push(lastDot.toLowerCase());
        }

        if (lower.includes("floorp")) candidates.push("floorp", "ablaze-floorp", "firefox", "browser");
        if (lower.includes("kitty")) candidates.push("kitty", "terminal", "utilities-terminal");
        if (lower.includes("nautilus")) candidates.push("org.gnome.Nautilus", "nautilus", "system-file-manager", "folder");
        if (lower.includes("gedit") || lower.includes("texteditor")) candidates.push("org.gnome.TextEditor", "text-editor", "gedit");
        if (lower.includes("settings")) candidates.push("preferences-system", "org.gnome.Settings", "gnome-control-center");
        if (lower.includes("code") || lower.includes("vscodium")) candidates.push("vscode", "vscodium", "com.visualstudio.code");
        if (lower.includes("obsidian")) candidates.push("obsidian");
        if (lower.includes("haruna")) candidates.push("org.kde.haruna", "haruna");

        for (let i = 0; i < candidates.length; i++) {
            let p = Quickshell.iconPath(candidates[i], true);
            if (p && p.length > 0) return p;
        }

        return Quickshell.iconPath(rawId, true);
    }

    width: 44; height: 44

    // ---- Hover background ----
    Rectangle {
        id: hoverBg
        anchors.centerIn: parent
        width: 40; height: 40; radius: 12
        color: itemArea.containsMouse
            ? Qt.rgba(ColorService.bgHover.r, ColorService.bgHover.g, ColorService.bgHover.b, 1.0)
            : (isActive
                ? Qt.rgba(ColorService.accentDim.r, ColorService.accentDim.g, ColorService.accentDim.b, 1.0)
                : "transparent")
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ---- App icon ----
    IconImage {
        id: appIcon
        anchors.centerIn: parent
        width: 28; height: 28
        source: root.resolvedIconPath
        smooth: true
        visible: backer.status === Image.Ready
    }

    // ---- Fallback letter ----
    Rectangle {
        anchors.centerIn: parent
        width: 28; height: 28; radius: 8
        color: ColorService.accentDim
        visible: appIcon.backer.status !== Image.Ready
        Behavior on color { ColorAnimation { duration: 400 } }
        Text {
            anchors.centerIn: parent
            text: displayName.length > 0 ? displayName[0].toUpperCase() : "?"
            color: ColorService.accent
            font.family: Theme.fontMain
            font.bold: true
            font.pixelSize: 14
            Behavior on color { ColorAnimation { duration: 400 } }
        }
    }

    // ---- Active / open indicator dots (ChromeOS style) ----
    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 3

        // Single dot for open but not active, filled accent for active
        Rectangle {
            width: isActive ? 14 : 4
            height: 3; radius: 2
            color: isActive ? ColorService.accent : ColorService.textSecondary
            opacity: isOpen ? 1.0 : 0.0
            Behavior on width   { NumberAnimation { duration: 180 } }
            Behavior on color   { ColorAnimation  { duration: 400 } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    // ---- Tooltip ----
    ToolTip {
        id: tooltip
        text: displayName
        visible: itemArea.containsMouse && displayName.length > 0
        delay: 600
        background: Rectangle {
            color: ColorService.bgElevated
            radius: 6
            border.color: Qt.rgba(1,1,1,0.1)
            border.width: 1
        }
        contentItem: Text {
            text: tooltip.text
            color: ColorService.textPrimary
            font.family: Theme.fontMain
            font.pixelSize: 12
        }
    }

    function launchNew() {
        let cmd = (pinData && pinData.exec) ? pinData.exec
                 : (openToplevel ? openToplevel.appId : "");
        if (cmd.length > 0) {
            let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
            p.command = ["sh", "-c", cmd];
            p.running = true;
        }
    }

    function togglePin() {
        if (isPinned && pinData) {
            PinsService.unpin(pinData.appId);
        } else if (openToplevel) {
            PinsService.pin(
                openToplevel.appId,
                openToplevel.title || openToplevel.appId,
                openToplevel.appId,
                openToplevel.appId
            );
        }
    }

    function closeWindow() {
        if (openToplevel) openToplevel.close();
    }

    signal requestContextMenu(real mouseX, real mouseY)

    // ---- Mouse interaction ----
    MouseArea {
        id: itemArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.requestContextMenu(mouse.x, mouse.y);
                return;
            }
            if (openToplevel) {
                if (isActive) {
                    // Already focused — toggle minimize / special workspace
                    Hyprland.dispatch("togglespecialworkspace");
                } else {
                    root.activateWindow();
                }
            } else if (pinData && pinData.exec) {
                // Launch the pinned app
                let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                p.command = ["sh", "-c", pinData.exec];
                p.running = true;
            }
        }
    }
}
