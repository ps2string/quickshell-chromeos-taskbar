import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."
import "../services"

Item {
    id: root
    anchors.fill: parent

    property string wallpaperDir: "/home/" + (Quickshell.env("USER") || "zafran") + "/Pictures/Wallpapers"
    property var    wallpaperFiles: []
    property int    selectedIndex: -1
    property string currentWallpaper: ""
    property bool   isApplying: false
    property string statusMsg: ""
    property bool   statusOk: true


    Process {
        id: lsProc
        command: ["bash", "-c",
            `find '${root.wallpaperDir}' -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) 2>/dev/null | sort`
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n").filter(l => l.length > 0);
                root.wallpaperFiles = lines;
                currentWpProc.running = true;
            }
        }
    }

    Process {
        id: currentWpProc
        command: ["bash", "-c",
            "hyprctl hyprpaper listactive 2>/dev/null | awk '{print $NF}' | head -1"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let wp = this.text.trim();
                if (wp.length > 0) {
                    root.currentWallpaper = wp;
                    let idx = root.wallpaperFiles.indexOf(wp);
                    if (idx >= 0) root.selectedIndex = idx;
                }
            }
        }
    }

    Process {
        id: applyProc
        stdout: StdioCollector { id: applyStdout }
        stderr: StdioCollector { id: applyStderr }
        onRunningChanged: {
            if (!running) {
                root.isApplying = false;
                if (exitCode === 0) {
                    root.statusMsg = "✓ Applied!";
                    root.statusOk = true;
                } else {
                    let err = applyStderr.text.trim() || applyStdout.text.trim();
                    root.statusMsg = "✗ Failed: " + (err.length > 0 ? err.substring(0, 80) : "exit " + exitCode);
                    root.statusOk = false;
                }
                statusClearTimer.restart();
            }
        }
    }

    Process {
        id: openDirProc
        command: ["xdg-open", root.wallpaperDir]
    }

    Process {
        id: matugenProc
        property string pendingColor: ""
        onRunningChanged: { if (!running && pendingColor !== "") { command = ["matugen", "color", "hex", pendingColor]; pendingColor = ""; } }
    }

    Timer {
        id: statusClearTimer
        interval: 4000
        repeat: false
        onTriggered: root.statusMsg = ""
    }

    function applyWallpaper(path) {
        if (root.isApplying || !path || applyProc.running) return;
        root.isApplying = true;
        root.statusMsg = "Applying…";
        root.currentWallpaper = path;
        let idx = root.wallpaperFiles.indexOf(path);
        if (idx >= 0) root.selectedIndex = idx;
        applyProc.command = [
            "python3",
            "/home/" + (Quickshell.env("USER") || "zafran") + "/theme-manager.py",
            "--apply", path
        ];
        applyProc.running = true;
    }

    Component.onCompleted: { lsProc.running = true; }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: parent.width - 16
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            Item { height: 4 }

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Text {
                    text: "Wallpaper & Theme"
                    font.family: Theme.fontMain
                    font.pixelSize: 22
                    font.bold: true
                    color: ColorService.textPrimary
                }
                Text {
                    text: "Click any wallpaper to apply it and regenerate Material You colors via matugen"
                    font.family: Theme.fontMain
                    font.pixelSize: 13
                    color: ColorService.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 110
                radius: 16
                color: ColorService.bgSurface
                visible: root.currentWallpaper.length > 0
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.currentWallpaper.length > 0 ? "file://" + root.currentWallpaper : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: false 
                    asynchronous: true
                    sourceSize: Qt.size(700, 120)
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48
                    radius: 16
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.55) }
                    }
                }

                RowLayout {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "Active: " + root.currentWallpaper.split("/").pop()
                        font.family: Theme.fontMain
                        font.pixelSize: 12
                        font.bold: true
                        color: "white"
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 7; height: 7; radius: 4
                        color: ColorService.success
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: true
                            NumberAnimation { from: 1.0; to: 0.3; duration: 1000 }
                            NumberAnimation { from: 0.3; to: 1.0; duration: 1000 }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 10
                visible: root.statusMsg.length > 0
                color: root.statusOk
                    ? Qt.alpha(ColorService.success, 0.15)
                    : Qt.alpha(ColorService.danger, 0.15)
                border.color: root.statusOk
                    ? Qt.alpha(ColorService.success, 0.3)
                    : Qt.alpha(ColorService.danger, 0.3)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Text {
                        text: root.isApplying ? "⏳" : (root.statusOk ? "✓" : "✗")
                        font.family: Theme.fontMain
                        font.pixelSize: 13
                        color: root.statusOk ? ColorService.success : ColorService.danger
                    }
                    Text {
                        text: root.statusMsg
                        font.family: Theme.fontMain
                        font.pixelSize: 12
                        color: root.statusOk ? ColorService.success : ColorService.danger
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: gridCardCol.implicitHeight + 28
                radius: 16
                color: ColorService.bgSurface

                ColumnLayout {
                    id: gridCardCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Wallpapers"
                            font.family: Theme.fontMain
                            font.pixelSize: 14
                            font.bold: true
                            color: ColorService.textPrimary
                        }
                        Text {
                            text: root.wallpaperFiles.length > 0
                                ? root.wallpaperFiles.length + " images"
                                : "Loading…"
                            font.family: Theme.fontMain
                            font.pixelSize: 12
                            color: ColorService.textSecondary
                        }
                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 30; height: 30; radius: 15
                            color: refreshMa.containsMouse
                                ? Qt.rgba(1, 1, 1, 0.1)
                                : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "󰑐"
                                font.family: Theme.fontIcon
                                font.pixelSize: 13
                                color: ColorService.accent
                            }
                            MouseArea {
                                id: refreshMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { if (!lsProc.running) lsProc.running = true; }
                            }
                        }
                        Rectangle {
                            implicitWidth: openFolderTxt.implicitWidth + 20
                            height: 30; radius: 15
                            color: openFolderMa.containsMouse
                                ? Qt.alpha(ColorService.accent, 0.2)
                                : Qt.alpha(ColorService.accent, 0.1)
                            Text {
                                id: openFolderTxt
                                anchors.centerIn: parent
                                text: "Open Folder"
                                font.family: Theme.fontMain
                                font.pixelSize: 11
                                font.bold: true
                                color: ColorService.accent
                            }
                            MouseArea {
                                id: openFolderMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    openDirProc.command = ["xdg-open", root.wallpaperDir];
                                    openDirProc.running = true;
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: root.wallpaperFiles.length === 0
                        Layout.alignment: Qt.AlignHCenter
                        Item { height: 12 }
                        Text {
                            text: "󰋫"
                            font.family: Theme.fontIcon
                            font.pixelSize: 32
                            color: ColorService.textSecondary
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "No wallpapers found in\n" + root.wallpaperDir
                            font.family: Theme.fontMain
                            font.pixelSize: 13
                            color: ColorService.textSecondary
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Item { height: 12 }
                    }

                    Grid {
                        id: wallGrid
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            model: root.wallpaperFiles

                            delegate: Rectangle {
                                readonly property string filePath: modelData
                                readonly property bool isCurrentWp: root.currentWallpaper === filePath
                                readonly property bool isSelected: root.selectedIndex === index

                                width: (wallGrid.width - wallGrid.columnSpacing * (wallGrid.columns - 1)) / wallGrid.columns
                                height: width * 0.5625 
                                radius: 12
                                color: "transparent"
                                border.color: isCurrentWp
                                    ? ColorService.success
                                    : (isSelected ? ColorService.accent : "transparent")
                                border.width: isCurrentWp ? 3 : (isSelected ? 2 : 0)
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: parent.border.width
                                    source: "file://" + filePath
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: false 
                                    asynchronous: true
                                    sourceSize: Qt.size(220, 124)
                                    opacity: status === Image.Ready ? 1.0 : 0.0
                                    Behavior on opacity {
                                        NumberAnimation { duration: 150 }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: Qt.rgba(1, 1, 1, 0.05)
                                    visible: parent.children[0].status !== Image.Ready
                                }

                                Rectangle {
                                    visible: isCurrentWp
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 5
                                    width: activeLbl.implicitWidth + 10
                                    height: 18; radius: 9
                                    color: ColorService.success
                                    Text {
                                        id: activeLbl
                                        anchors.centerIn: parent
                                        text: "Active"
                                        font.family: Theme.fontMain
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: "white"
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: thumbMa.containsMouse && !root.isApplying
                                        ? Qt.rgba(0, 0, 0, 0.30)
                                        : (root.isApplying && isSelected
                                            ? Qt.rgba(0, 0, 0, 0.40)
                                            : "transparent")

                                    Text {
                                        anchors.centerIn: parent
                                        visible: thumbMa.containsMouse && !root.isApplying
                                        text: "Apply"
                                        font.family: Theme.fontMain
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: "white"
                                    }

                                    Item {
                                        anchors.centerIn: parent
                                        visible: root.isApplying && isSelected
                                        width: 24; height: 24

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 24; height: 24; radius: 12
                                            color: Qt.rgba(0, 0, 0, 0.5)
                                        }
                                        SequentialAnimation on rotation {
                                            loops: Animation.Infinite
                                            running: root.isApplying && isSelected
                                            NumberAnimation { from: 0; to: 360; duration: 1000 }
                                        }
                                        Rectangle {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 3; height: 8; radius: 2
                                            color: ColorService.accent
                                        }
                                    }
                                }

                                MouseArea {
                                    id: thumbMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    preventStealing: false
                                    onClicked: {
                                        if (!root.isApplying) {
                                            root.applyWallpaper(filePath);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: accentCol.implicitHeight + 24
                radius: 16
                color: ColorService.bgSurface

                ColumnLayout {
                    id: accentCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Text {
                        text: "Manual Accent Override"
                        font.family: Theme.fontMain
                        font.pixelSize: 14
                        font.bold: true
                        color: ColorService.textPrimary
                    }
                    Text {
                        text: "Apply a custom accent color without changing the wallpaper"
                        font.family: Theme.fontMain
                        font.pixelSize: 12
                        color: ColorService.textSecondary
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Flow {
                        spacing: 10
                        Layout.fillWidth: true

                        Repeater {
                            model: [
                                { name: "Blue",    color: "#8ab4f8" },
                                { name: "Lime",    color: "#c0ce7d" },
                                { name: "Emerald", color: "#81c995" },
                                { name: "Violet",  color: "#c58af9" },
                                { name: "Coral",   color: "#ff8bcb" },
                                { name: "Amber",   color: "#fdd663" },
                                { name: "Teal",    color: "#78d9ec" },
                                { name: "Orange",  color: "#ff9d6f" },
                                { name: "Rose",    color: "#f48fb1" },
                                { name: "Indigo",  color: "#9fa8da" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool isCurrent:
                                    ColorService.accent.toString().slice(0, 7).toLowerCase() === modelData.color.toLowerCase()

                                width: 34; height: 34; radius: 17
                                color: modelData.color
                                border.color: "white"
                                border.width: isCurrent ? 3 : 0
                                scale: palMa.containsMouse ? 1.15 : (isCurrent ? 1.08 : 1.0)
                                Behavior on scale {
                                    NumberAnimation { duration: 120 }
                                }

                                ToolTip {
                                    visible: palMa.containsMouse
                                    text: modelData.name
                                    delay: 400
                                }

                                MouseArea {
                                    id: palMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                       
                                        matugenProc.command = ["matugen", "color", "hex", modelData.color];
                                        if (!matugenProc.running) matugenProc.running = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 50
                radius: 14
                color: ColorService.bgSurface

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    Text {
                        text: "󰉖"
                        font.family: Theme.fontIcon
                        font.pixelSize: 16
                        color: ColorService.accent
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Wallpaper Directory"
                            font.family: Theme.fontMain
                            font.pixelSize: 12
                            font.bold: true
                            color: ColorService.textPrimary
                        }
                        Text {
                            text: root.wallpaperDir
                            font.family: Theme.fontMain
                            font.pixelSize: 11
                            color: ColorService.textSecondary
                            elide: Text.ElideLeft
                            Layout.fillWidth: true
                        }
                    }
                    Rectangle {
                        implicitWidth: openDirTxt.implicitWidth + 14
                        height: 26; radius: 13
                        color: openDirMa.containsMouse
                            ? Qt.alpha(ColorService.accent, 0.2)
                            : Qt.alpha(ColorService.accent, 0.1)
                        Text {
                            id: openDirTxt
                            anchors.centerIn: parent
                            text: "Open"
                            font.family: Theme.fontMain
                            font.pixelSize: 11
                            font.bold: true
                            color: ColorService.accent
                        }
                        MouseArea {
                            id: openDirMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                openDirProc.command = ["xdg-open", root.wallpaperDir];
                                openDirProc.running = true;
                            }
                        }
                    }
                }
            }

            Item { height: 16 }
        }
    }
}
