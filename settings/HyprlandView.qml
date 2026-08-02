import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."
import "../services"

ScrollView {
    id: root
    anchors.fill: parent
    contentWidth: availableWidth
    clip: true

    property string hyprCfgPath: Quickshell.env("HOME") + "/.config/hypr/hyprland.conf"
    property string keybindList: ""
    property bool   gapsLoaded: false
    property int    gapsIn:  5
    property int    gapsOut: 10
    property int    borderSz: 2
    property bool   animationsOn: true

    Process {
        id: keybindProc
        command: ["bash", "-c",
            "hyprctl binds -j 2>/dev/null | python3 -c \"" +
            "import json,sys;" +
            "binds=json.load(sys.stdin);" +
            "[print(f\\\"{'SUPER' if b.get('modmask',0)==64 else hex(b.get('modmask',0))} + {b.get('key','')} => {b.get('dispatcher','')} {b.get('arg','')}\\\") " +
            "for b in binds if b.get('dispatcher','')]\" 2>/dev/null | head -30"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { root.keybindList = this.text.trim(); }
        }
    }

    Process {
        id: hyprVarsProc
        command: ["bash", "-c",
            "hyprctl getoption general:gaps_in -j 2>/dev/null | python3 -c \"import json,sys; d=json.load(sys.stdin); print('GAPSIN:'+str(d.get('int',5)))\"; " +
            "hyprctl getoption general:gaps_out -j 2>/dev/null | python3 -c \"import json,sys; d=json.load(sys.stdin); print('GAPSOUT:'+str(d.get('int',10)))\"; " +
            "hyprctl getoption general:border_size -j 2>/dev/null | python3 -c \"import json,sys; d=json.load(sys.stdin); print('BORDER:'+str(d.get('int',2)))\"; "
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split("\n");
                for (let line of lines) {
                    if (line.startsWith("GAPSIN:"))  root.gapsIn   = parseInt(line.substring(7))  || 5;
                    if (line.startsWith("GAPSOUT:")) root.gapsOut  = parseInt(line.substring(8))  || 10;
                    if (line.startsWith("BORDER:"))  root.borderSz = parseInt(line.substring(7))  || 2;
                }
                root.gapsLoaded = true;
            }
        }
    }

    // Declared process for live hyprland keyword changes
    Process {
        id: hyprKwProc
    }

    // Declared process for opening config file
    Process {
        id: openCfgProc
    }

    function hyprKw(keyword, value) {
        if (hyprKwProc.running) return;
        hyprKwProc.command = ["hyprctl", "keyword", keyword, value.toString()];
        hyprKwProc.running = true;
    }

    ColumnLayout {
        width: root.availableWidth - 16
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20

        Item { height: 4 }

        // Header
        ColumnLayout {
            spacing: 4; Layout.fillWidth: true
            Text { text: "Hyprland"; font.family: Theme.fontMain; font.pixelSize: 22; font.bold: true; color: ColorService.textPrimary }
            Text { text: "Live compositor tweaks, keybindings, workspace rules"; font.family: Theme.fontMain; font.pixelSize: 13; color: ColorService.textSecondary }
        }

        // --- Live Tweaks ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: tweaksCol.implicitHeight + 28
            radius: 20; color: ColorService.bgSurface

            ColumnLayout {
                id: tweaksCol; anchors.fill: parent; anchors.margins: 16; spacing: 16

                Text { text: "Live Tweaks"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }
                Text { text: "Changes apply instantly. Permanent changes require editing hyprland.conf"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary; wrapMode: Text.WordWrap; Layout.fillWidth: true }

                // Gaps In
                RowLayout { Layout.fillWidth: true; spacing: 12
                    Rectangle { width: 36; height: 36; radius: 18; color: Qt.alpha(ColorService.accent, 0.15)
                        Text { anchors.centerIn: parent; text: "󰘕"; font.family: Theme.fontIcon; font.pixelSize: 14; color: ColorService.accent }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                        RowLayout { Layout.fillWidth: true
                            Text { text: "Inner Gaps"; font.family: Theme.fontMain; font.pixelSize: 13; font.bold: true; color: ColorService.textPrimary }
                            Item { Layout.fillWidth: true }
                            Text { text: gapsInWrapper.val + "px"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary }
                        }
                        Item {
                            id: gapsInWrapper; Layout.fillWidth: true; height: 24
                            property real val: root.gapsIn
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Qt.rgba(1,1,1,0.12)
                                Rectangle { width: parent.width * (gapsInWrapper.val / 40); height: parent.height; radius: 3; color: ColorService.accent }
                            }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; x: Math.max(0, Math.min(parent.width - width, (parent.width - width) * (gapsInWrapper.val / 40))); width: 20; height: 20; radius: 10; color: giMouse.pressed ? Qt.lighter(ColorService.accent, 1.3) : ColorService.accent; scale: giMouse.pressed ? 1.2 : 1; Behavior on scale { NumberAnimation { duration: 120 } } }
                            MouseArea { id: giMouse; anchors.fill: parent; preventStealing: true
                                function upd(m) { let v = Math.round(Math.max(0, Math.min(40, (m.x / width) * 40))); gapsInWrapper.val = v; root.gapsIn = v; }
                                onPressed: (m) => upd(m); onPositionChanged: (m) => { if (pressed) upd(m) }
                                onReleased: { root.hyprKw("general:gaps_in", root.gapsIn); }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.06) }

                // Gaps Out
                RowLayout { Layout.fillWidth: true; spacing: 12
                    Rectangle { width: 36; height: 36; radius: 18; color: Qt.alpha(ColorService.accent, 0.15)
                        Text { anchors.centerIn: parent; text: "󰘖"; font.family: Theme.fontIcon; font.pixelSize: 14; color: ColorService.accent }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                        RowLayout { Layout.fillWidth: true
                            Text { text: "Outer Gaps"; font.family: Theme.fontMain; font.pixelSize: 13; font.bold: true; color: ColorService.textPrimary }
                            Item { Layout.fillWidth: true }
                            Text { text: gapsOutWrapper.val + "px"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary }
                        }
                        Item {
                            id: gapsOutWrapper; Layout.fillWidth: true; height: 24
                            property real val: root.gapsOut
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Qt.rgba(1,1,1,0.12)
                                Rectangle { width: parent.width * (gapsOutWrapper.val / 80); height: parent.height; radius: 3; color: ColorService.accent }
                            }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; x: Math.max(0, Math.min(parent.width - width, (parent.width - width) * (gapsOutWrapper.val / 80))); width: 20; height: 20; radius: 10; color: goMouse.pressed ? Qt.lighter(ColorService.accent, 1.3) : ColorService.accent; scale: goMouse.pressed ? 1.2 : 1; Behavior on scale { NumberAnimation { duration: 120 } } }
                            MouseArea { id: goMouse; anchors.fill: parent; preventStealing: true
                                function upd(m) { let v = Math.round(Math.max(0, Math.min(80, (m.x / width) * 80))); gapsOutWrapper.val = v; root.gapsOut = v; }
                                onPressed: (m) => upd(m); onPositionChanged: (m) => { if (pressed) upd(m) }
                                onReleased: { root.hyprKw("general:gaps_out", root.gapsOut); }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.06) }

                // Border Size
                RowLayout { Layout.fillWidth: true; spacing: 12
                    Rectangle { width: 36; height: 36; radius: 18; color: Qt.alpha(ColorService.accent, 0.15)
                        Text { anchors.centerIn: parent; text: "󰢚"; font.family: Theme.fontIcon; font.pixelSize: 14; color: ColorService.accent }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 4
                        RowLayout { Layout.fillWidth: true
                            Text { text: "Border Size"; font.family: Theme.fontMain; font.pixelSize: 13; font.bold: true; color: ColorService.textPrimary }
                            Item { Layout.fillWidth: true }
                            Text { text: borderWrapper.val + "px"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary }
                        }
                        Item {
                            id: borderWrapper; Layout.fillWidth: true; height: 24
                            property real val: root.borderSz
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Qt.rgba(1,1,1,0.12)
                                Rectangle { width: parent.width * (borderWrapper.val / 10); height: parent.height; radius: 3; color: ColorService.accent }
                            }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; x: Math.max(0, Math.min(parent.width - width, (parent.width - width) * (borderWrapper.val / 10))); width: 20; height: 20; radius: 10; color: bsMouse.pressed ? Qt.lighter(ColorService.accent, 1.3) : ColorService.accent; scale: bsMouse.pressed ? 1.2 : 1; Behavior on scale { NumberAnimation { duration: 120 } } }
                            MouseArea { id: bsMouse; anchors.fill: parent; preventStealing: true
                                function upd(m) { let v = Math.round(Math.max(0, Math.min(10, (m.x / width) * 10))); borderWrapper.val = v; root.borderSz = v; }
                                onPressed: (m) => upd(m); onPositionChanged: (m) => { if (pressed) upd(m) }
                                onReleased: { root.hyprKw("general:border_size", root.borderSz); }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.06) }

                // Animations toggle
                RowLayout { Layout.fillWidth: true; spacing: 12
                    Rectangle { width: 36; height: 36; radius: 18; color: Qt.alpha(ColorService.accent, 0.15)
                        Text { anchors.centerIn: parent; text: "󰚀"; font.family: Theme.fontIcon; font.pixelSize: 14; color: ColorService.accent }
                    }
                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                        Text { text: "Animations"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }
                        Text { text: "Enable Hyprland window animations"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary }
                    }
                    M3Switch {
                        checked: root.animationsOn
                        onToggled: {
                            root.animationsOn = !root.animationsOn;
                            root.hyprKw("animations:enabled", root.animationsOn ? "true" : "false");
                        }
                    }
                }
            }
        }

        // --- Keybindings ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: kbCol.implicitHeight + 28
            radius: 20; color: ColorService.bgSurface

            ColumnLayout {
                id: kbCol; anchors.fill: parent; anchors.margins: 16; spacing: 10

                RowLayout { Layout.fillWidth: true
                    Text { text: "Active Keybindings"; font.family: Theme.fontMain; font.pixelSize: 14; font.bold: true; color: ColorService.textPrimary }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: reloadKbTxt.implicitWidth + 16; height: 26; radius: 13
                        color: reloadKbMouse.containsMouse ? Qt.alpha(ColorService.accent, 0.2) : Qt.alpha(ColorService.accent, 0.12)
                        Text { id: reloadKbTxt; anchors.centerIn: parent; text: "Refresh"; font.family: Theme.fontMain; font.pixelSize: 11; font.bold: true; color: ColorService.accent }
                        MouseArea { id: reloadKbMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: keybindProc.running = true }
                    }
                }

                Repeater {
                    model: root.keybindList.split("\n").filter(l => l.trim().length > 0).slice(0, 20)
                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true; height: 32; radius: 8
                        color: index % 2 === 0 ? "transparent" : Qt.rgba(1,1,1,0.03)
                        RowLayout { anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                            Text {
                                text: modelData.split("=>")[0].trim()
                                font.family: Theme.fontMain; font.pixelSize: 12; font.bold: true
                                color: ColorService.accent; width: 140
                            }
                            Text {
                                text: "→ " + (modelData.split("=>")[1] || "").trim()
                                font.family: Theme.fontMain; font.pixelSize: 12
                                color: ColorService.textSecondary; elide: Text.ElideRight; Layout.fillWidth: true
                            }
                        }
                    }
                }

                Text {
                    visible: root.keybindList.trim().length === 0
                    text: "No keybindings loaded. Is Hyprland running?"; font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // --- Open Config ---
        Rectangle {
            Layout.fillWidth: true; height: 52; radius: 16
            color: openCfgMouse.containsMouse ? Qt.alpha(ColorService.accent, 0.15) : ColorService.bgSurface
            Behavior on color { ColorAnimation { duration: 150 } }
            RowLayout { anchors.fill: parent; anchors.margins: 14; spacing: 12
                Text { text: "󰈔"; font.family: Theme.fontIcon; font.pixelSize: 18; color: ColorService.accent }
                Text { text: "Open hyprland.conf in editor"; font.family: Theme.fontMain; font.pixelSize: 13; font.bold: true; color: ColorService.textPrimary; Layout.fillWidth: true }
                Text { text: "󰌑"; font.family: Theme.fontIcon; font.pixelSize: 16; color: ColorService.textSecondary }
            }
            MouseArea { id: openCfgMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!openCfgProc.running) {
                        openCfgProc.command = ["xdg-open", root.hyprCfgPath];
                        openCfgProc.running = true;
                    }
                }
            }
        }

        Item { height: 16 }
    }
}
