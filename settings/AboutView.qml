import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."
import "../services"

ScrollView {
    id: root
    anchors.fill: parent
    contentWidth: availableWidth
    clip: true

    property string kernelVer:  "Linux"
    property string hostName:   "Desktop"
    property string uptimeStr:  ""
    property string cpuInfo:    ""
    property string memInfo:    ""
    property string gpuInfo:    ""
    property string diskInfo:   ""
    property string pkgCount:   ""
    property string ipAddr:     ""
    property string shellName:  ""

    Process {
        id: quickActionProc
    }

    Process {
        id: infoProc
        command: ["bash", "-c", [
            "echo 'KERNEL:'$(uname -sr)",
            "echo 'HOST:'$(hostname)",
            "echo 'UPTIME:'$(uptime -p | sed 's/up //')",
            "echo 'CPU:'$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs || echo 'Unknown')",
            "echo 'RAM:'$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%.1f GB used / %.1f GB total\", (t-a)/1048576, t/1048576}' /proc/meminfo)",
            "echo 'GPU:'$(lspci -mm 2>/dev/null | grep -iE 'VGA|3D|Display' | awk -F'\"' '{print $6\" \"$8}' | head -1 | xargs || echo 'Unknown')",
            "echo 'DISK:'$(df -h / 2>/dev/null | awk 'NR==2{print $3\" used / \"$2\" total (\"$5\")\"}' )",
            "echo 'PKGS:'$(pacman -Q 2>/dev/null | wc -l || dpkg --get-selections 2>/dev/null | wc -l || echo '?')",
            "echo 'IP:'$(ip route get 1 2>/dev/null | awk '{print $7}' | head -1 || echo '')",
            "echo 'SHELL:'$(basename $SHELL)"
        ].join(";")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split("\n");
                for (let line of lines) {
                    let sep = line.indexOf(":");
                    if (sep < 0) continue;
                    let key = line.substring(0, sep);
                    let val = line.substring(sep + 1).trim();
                    switch(key) {
                        case "KERNEL": root.kernelVer  = val; break;
                        case "HOST":   root.hostName   = val; break;
                        case "UPTIME": root.uptimeStr  = val; break;
                        case "CPU":    root.cpuInfo    = val; break;
                        case "RAM":    root.memInfo    = val; break;
                        case "GPU":    root.gpuInfo    = val; break;
                        case "DISK":   root.diskInfo   = val; break;
                        case "PKGS":   root.pkgCount   = val + " packages"; break;
                        case "IP":     root.ipAddr     = val; break;
                        case "SHELL":  root.shellName  = val; break;
                    }
                }
            }
        }
    }

    Timer { interval: 30000; running: true; repeat: true; onTriggered: infoProc.running = true }

    ColumnLayout {
        width: root.availableWidth - 16
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20

        Item { height: 4 }

        // ── Hero Identity Card ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 110
            radius: 24
            // Gradient card
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(ColorService.accent.r * 0.5, ColorService.accent.g * 0.5, ColorService.accent.b * 0.5, 0.22) }
                GradientStop { position: 1.0; color: Qt.rgba(ColorService.accentDim.r * 0.4, ColorService.accentDim.g * 0.4, ColorService.accentDim.b * 0.4, 0.14) }
            }
            border.color: Qt.alpha(ColorService.accent, 0.25); border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 18

                // Avatar circle
                Rectangle {
                    width: 68; height: 68; radius: 34
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Qt.alpha(ColorService.accent, 0.55) }
                        GradientStop { position: 1; color: Qt.alpha(ColorService.accentDim, 0.75) }
                    }
                    border.color: Qt.rgba(1,1,1,0.25); border.width: 1.5

                    Text {
                        anchors.centerIn: parent
                        text: "󰌽"
                        font.family: Theme.fontIcon
                        font.pixelSize: 32
                        color: ColorService.bgBase
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: root.hostName
                        font.family: Theme.fontMain
                        font.pixelSize: 20
                        font.bold: true
                        color: ColorService.textPrimary
                    }

                    RowLayout {
                        spacing: 8
                        Text { text: "󰀄"; font.family: Theme.fontIcon; font.pixelSize: 12; color: ColorService.accent }
                        Text {
                            text: (Quickshell.env("USER") || "user") + " · Hyprland · Wayland"
                            font.family: Theme.fontMain; font.pixelSize: 12; color: ColorService.textSecondary
                        }
                    }

                    // Uptime badge
                    Rectangle {
                        visible: root.uptimeStr.length > 0
                        implicitWidth: uptimeRow.implicitWidth + 16
                        height: 22; radius: 11
                        color: Qt.alpha(ColorService.accent, 0.12)
                        border.color: Qt.alpha(ColorService.accent, 0.25); border.width: 1

                        RowLayout {
                            id: uptimeRow
                            anchors.centerIn: parent
                            spacing: 5
                            Text { text: "󰔛"; font.family: Theme.fontIcon; font.pixelSize: 11; color: ColorService.accent }
                            Text { text: "Up " + root.uptimeStr; font.family: Theme.fontMain; font.pixelSize: 11; color: ColorService.accent }
                        }
                    }
                }
            }
        }

        // ── Hardware Card ──────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: hwCardCol.implicitHeight + 32
            radius: 22; color: ColorService.bgSurface
            border.color: Qt.rgba(1,1,1,0.06); border.width: 1

            ColumnLayout {
                id: hwCardCol; anchors.fill: parent; anchors.margins: 18; spacing: 0

                Text { text: "Hardware"; font.family: Theme.fontMain; font.pixelSize: 12; font.bold: true; color: ColorService.textSecondary; font.letterSpacing: 1.2; bottomPadding: 12 }

                Repeater {
                    model: [
                        { icon: "󰍛", label: "CPU",    value: root.cpuInfo,  accent: "#78d9ec" },
                        { icon: "󰘚", label: "Memory", value: root.memInfo,  accent: "#81c995" },
                        { icon: "󰄴", label: "GPU",    value: root.gpuInfo,  accent: "#ff9d6f" },
                        { icon: "󰋊", label: "Disk",   value: root.diskInfo, accent: "#fdd663" },
                    ]

                    delegate: Column {
                        required property var modelData
                        width: parent ? parent.width : 0

                        Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.06) }

                        RowLayout {
                            width: parent.width; height: 46; spacing: 14

                            Rectangle {
                                width: 32; height: 32; radius: 16
                                color: Qt.alpha(modelData.accent, 0.12)
                                Text { anchors.centerIn: parent; text: modelData.icon; font.family: Theme.fontIcon; font.pixelSize: 15; color: modelData.accent }
                            }

                            Text { text: modelData.label; font.family: Theme.fontMain; font.pixelSize: 13; color: ColorService.textSecondary; width: 54 }

                            Text {
                                text: modelData.value || "Loading…"
                                font.family: Theme.fontMain; font.pixelSize: 13; color: ColorService.textPrimary
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        // ── Environment Card ───────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: envCardCol.implicitHeight + 32
            radius: 22; color: ColorService.bgSurface
            border.color: Qt.rgba(1,1,1,0.06); border.width: 1

            ColumnLayout {
                id: envCardCol; anchors.fill: parent; anchors.margins: 18; spacing: 0

                Text { text: "Environment"; font.family: Theme.fontMain; font.pixelSize: 12; font.bold: true; color: ColorService.textSecondary; font.letterSpacing: 1.2; bottomPadding: 12 }

                Repeater {
                    model: [
                        { icon: "󰣑", label: "Kernel",   value: root.kernelVer,                             accent: ColorService.accent },
                        { icon: "󰀄", label: "User",     value: Quickshell.env("USER") || "user",           accent: ColorService.accent },
                        { icon: "󰆍", label: "Shell",    value: root.shellName,                             accent: ColorService.accent },
                        { icon: "󰘔", label: "Packages", value: root.pkgCount,                              accent: ColorService.accent },
                        { icon: "󰩟", label: "IP",       value: root.ipAddr || "Not connected",             accent: ColorService.accent },
                    ]

                    delegate: Column {
                        required property var modelData
                        width: parent ? parent.width : 0

                        Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.06) }

                        RowLayout {
                            width: parent.width; height: 46; spacing: 14

                            Rectangle {
                                width: 32; height: 32; radius: 16
                                color: Qt.alpha(ColorService.accent, 0.1)
                                Text { anchors.centerIn: parent; text: modelData.icon; font.family: Theme.fontIcon; font.pixelSize: 15; color: ColorService.accent }
                            }

                            Text { text: modelData.label; font.family: Theme.fontMain; font.pixelSize: 13; color: ColorService.textSecondary; width: 62 }

                            Text {
                                text: modelData.value || "Unknown"
                                font.family: Theme.fontMain; font.pixelSize: 13; color: ColorService.textPrimary
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        // ── Quickshell Config Card ─────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: qsCardCol.implicitHeight + 32
            radius: 22; color: ColorService.bgSurface
            border.color: Qt.rgba(1,1,1,0.06); border.width: 1

            ColumnLayout {
                id: qsCardCol; anchors.fill: parent; anchors.margins: 18; spacing: 0

                Text { text: "Quickshell"; font.family: Theme.fontMain; font.pixelSize: 12; font.bold: true; color: ColorService.textSecondary; font.letterSpacing: 1.2; bottomPadding: 12 }

                Repeater {
                    model: [
                        { icon: "󰉖", label: "Config", value: "~/.config/quickshell" },
                        { icon: "󰉏", label: "Font",   value: Theme.fontMain },
                        { icon: "󰉫", label: "Icons",  value: "Papirus" },
                        { icon: "󰮒", label: "Accent", value: ColorService.accent.toString().toUpperCase().substring(0,7) },
                    ]

                    delegate: Column {
                        required property var modelData
                        width: parent ? parent.width : 0

                        Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.06) }

                        RowLayout {
                            width: parent.width; height: 46; spacing: 14

                            Rectangle {
                                width: 32; height: 32; radius: 16
                                color: Qt.alpha(ColorService.accent, 0.1)
                                Text { anchors.centerIn: parent; text: modelData.icon; font.family: Theme.fontIcon; font.pixelSize: 15; color: ColorService.accent }
                            }

                            Text { text: modelData.label; font.family: Theme.fontMain; font.pixelSize: 13; color: ColorService.textSecondary; width: 62 }

                            Text {
                                text: modelData.value
                                font.family: Theme.fontMain; font.pixelSize: 13; color: ColorService.textPrimary
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }

                            // Accent swatch
                            Rectangle {
                                visible: modelData.label === "Accent"
                                width: 22; height: 22; radius: 11
                                color: ColorService.accent
                                border.color: Qt.rgba(1,1,1,0.3); border.width: 1.5
                            }
                        }
                    }
                }
            }
        }

        // ── Quick Actions ──────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: actionsCardCol.implicitHeight + 32
            radius: 22; color: ColorService.bgSurface
            border.color: Qt.rgba(1,1,1,0.06); border.width: 1

            ColumnLayout {
                id: actionsCardCol; anchors.fill: parent; anchors.margins: 18; spacing: 12

                Text { text: "Quick Actions"; font.family: Theme.fontMain; font.pixelSize: 12; font.bold: true; color: ColorService.textSecondary; font.letterSpacing: 1.2 }

                RowLayout {
                    Layout.fillWidth: true; spacing: 10

                    Repeater {
                        model: [
                            { icon: "󰑓", label: "Reload Shell",   cmd: "bash -c 'killall quickshell; quickshell &'",                        accent: ColorService.accent },
                            { icon: "󰥔", label: "System Monitor", cmd: "bash -c 'kitty btop &'",                             accent: "#78d9ec" },
                            { icon: "󰄴", label: "GPU Info",       cmd: "bash -c 'kitty -e nvidia-smi || kitty -e radeontop &'", accent: "#ff9d6f" },
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; height: 64; radius: 16
                            color: actMouse.containsMouse
                                ? Qt.alpha(modelData.accent, 0.22)
                                : Qt.alpha(modelData.accent, 0.10)
                            border.color: actMouse.containsMouse
                                ? Qt.alpha(modelData.accent, 0.45)
                                : Qt.alpha(modelData.accent, 0.2)
                            border.width: 1.5
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            scale: actMouse.pressed ? 0.94 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 5
                                Text { text: modelData.icon; font.family: Theme.fontIcon; font.pixelSize: 20; color: modelData.accent; Layout.alignment: Qt.AlignHCenter }
                                Text { text: modelData.label; font.family: Theme.fontMain; font.pixelSize: 11; font.bold: true; color: ColorService.textPrimary; Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter }
                            }

                            MouseArea {
                                id: actMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!quickActionProc.running) {
                                        quickActionProc.command = ["bash", "-c", modelData.cmd];
                                        quickActionProc.running = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { height: 16 }
    }
}
