import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../services"

PopupWindow {
    id: launcherRoot

    implicitWidth:  540
    implicitHeight: 650
    visible: false
    color: "transparent"
    grabFocus: true

    property bool isOpen: false

    function launchApp(appData) {
        if (!appData) return;
        if (appData.execute) {
            appData.execute();
        } else if (appData.exec) {
            let p = Qt.createQmlObject('import Quickshell.Io; Process {}', launcherRoot);
            p.command = ["sh", "-c", appData.exec];
            p.running = true;
        }
    }
    function getFilteredApps() {
        let all = [];
        if (typeof DesktopEntries !== "undefined" && DesktopEntries.applications && DesktopEntries.applications.values) {
            let vals = DesktopEntries.applications.values;
            for (let i = 0; i < vals.length; i++) {
                if (vals[i]) all.push(vals[i]);
            }
        }

        all.sort((a, b) => (a.name || "").localeCompare(b.name || ""));

        let q = searchInput.text.toLowerCase().trim();
        if (!q) return all;

        return all.filter(app => {
            if (!app) return false;
            let n = (app.name || "").toLowerCase();
            let g = (app.genericName || "").toLowerCase();
            let e = (app.execString || app.exec || "").toLowerCase();
            let id = (app.id || "").toLowerCase();
            return n.includes(q) || g.includes(q) || e.includes(q) || id.includes(q);
        });
    }

    function launchFirstResult() {
        let results = getFilteredApps();
        if (results.length > 0) {
            launchApp(results[0]);
            close();
        }
    }

    function open() {
        searchInput.text = "";
        visible = true;
        isOpen = true;
        searchInput.forceActiveFocus();
    }

    function close() {
        isOpen = false;
        closeTimer.start();
    }

    function toggle() {
        if (isOpen) close();
        else open();
    }

    Timer {
        id: closeTimer
        interval: 220
        repeat: false
        onTriggered: {
            visible = false;
            searchInput.text = "";
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            isOpen = true;
            searchInput.forceActiveFocus();
        } else {
            isOpen = false;
        }
    }

    Rectangle {
        id: launcherContainer
        anchors.fill: parent
        color: Qt.rgba(ColorService.bgBase.r, ColorService.bgBase.g, ColorService.bgBase.b, 0.94)
        radius: 28
        border.color: Qt.alpha(ColorService.accent, 0.2)
        border.width: 1

        scale: launcherRoot.isOpen ? 1.0 : 0.94
        opacity: launcherRoot.isOpen ? 1.0 : 0.0
        transform: Translate {
            y: launcherRoot.isOpen ? 0 : 30
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        }

        Behavior on scale   { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on color   { ColorAnimation  { duration: 400 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                height: 50
                radius: 25
                color: ColorService.bgElevated
                border.color: searchInput.activeFocus ? ColorService.accent : Qt.alpha(ColorService.accent, 0.15)
                border.width: searchInput.activeFocus ? 2 : 1

                Behavior on border.color { ColorAnimation { duration: 180 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Text {
                        text: "󰍉"
                        font.family: Theme.fontIcon
                        font.pixelSize: 18
                        color: searchInput.activeFocus ? ColorService.accent : ColorService.textSecondary
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        placeholderText: "Search apps…"
                        placeholderTextColor: Qt.alpha(ColorService.textSecondary, 0.7)
                        color: ColorService.textPrimary
                        font.family: Theme.fontMain
                        font.pixelSize: 15
                        font.bold: true
                        background: null

                        Keys.onEscapePressed: launcherRoot.close()
                        Keys.onReturnPressed: launcherRoot.launchFirstResult()
                        Keys.onEnterPressed:  launcherRoot.launchFirstResult()
                    }

                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: clearArea.containsMouse ? Qt.alpha(ColorService.accent, 0.2) : Qt.alpha(ColorService.accent, 0.1)
                        visible: searchInput.text.length > 0
                        scale: clearArea.containsMouse ? 1.1 : 1.0

                        Behavior on scale { NumberAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: Theme.fontIcon
                            font.pixelSize: 12
                            color: ColorService.accent
                        }

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: searchInput.text = ""
                        }
                    }
                }
            }

            ColumnLayout {
                visible: searchInput.text.length === 0 && PinsService.pins.length > 0
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Favorites"
                    color: ColorService.accent
                    font.family: Theme.fontMain
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 0.6
                    leftPadding: 4
                }

                ListView {
                    id: pinsList
                    Layout.fillWidth: true
                    implicitHeight: 42
                    orientation: ListView.Horizontal
                    spacing: 8
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    model: PinsService.pins

                    delegate: Rectangle {
                        width: 92; height: 42
                        radius: 21
                        color: pinnedArea.containsMouse ? Qt.alpha(ColorService.accent, 0.22) : Qt.alpha(ColorService.accent, 0.1)
                        border.color: pinnedArea.containsMouse ? ColorService.accent : "transparent"
                        border.width: 1
                        scale: pinnedArea.containsMouse ? 1.03 : 1.0

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            IconImage {
                                width: 22; height: 22
                                source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                                visible: status === Image.Ready
                                smooth: true
                            }

                            Text {
                                text: modelData.name || "App"
                                color: ColorService.textPrimary
                                font.family: Theme.fontMain
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.maximumWidth: 50
                            }
                        }

                        MouseArea {
                            id: pinnedArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.exec) {
                                    let p = Qt.createQmlObject('import Quickshell.Io; Process {}', launcherRoot);
                                    p.command = ["sh", "-c", modelData.exec]; p.running = true;
                                }
                                launcherRoot.close();
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.alpha(ColorService.accent, 0.12)
                    Layout.topMargin: 2
                }
            }

            Text {
                text: searchInput.text.length === 0 ? "All Applications" : ("Results for \"" + searchInput.text + "\"")
                color: ColorService.textSecondary
                font.family: Theme.fontMain
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 0.6
                leftPadding: 4
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: appList
                    anchors.fill: parent
                    anchors.bottomMargin: 10
                    spacing: 6
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    model: launcherRoot.getFilteredApps()

                    delegate: Item {
                        width: appList.width
                        height: 56

                        Rectangle {
                            id: tileBg
                            anchors.fill: parent
                            radius: 16
                            color: listItemArea.containsMouse ? Qt.alpha(ColorService.accent, 0.15) : "transparent"
                            border.color: listItemArea.containsMouse ? Qt.alpha(ColorService.accent, 0.3) : "transparent"
                            border.width: 1

                            scale: listItemArea.containsMouse ? 1.01 : 1.0

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 16
                                spacing: 14

                                Rectangle {
                                    width: 40; height: 40
                                    radius: 13
                                    color: Qt.alpha(ColorService.accent, 0.12)
                                    border.color: Qt.alpha(ColorService.accent, 0.2)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    IconImage {
                                        id: listIcon
                                        anchors.centerIn: parent
                                        width: 24; height: 24
                                        source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                                        visible: status === Image.Ready
                                        smooth: true
                                    }

                                    Rectangle {
                                        anchors.fill: parent; radius: 13
                                        color: ColorService.accentDim
                                        visible: listIcon.status !== Image.Ready
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.name ? modelData.name[0].toUpperCase() : "A"
                                            color: ColorService.accent
                                            font.family: Theme.fontMain
                                            font.pixelSize: 15
                                            font.bold: true
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    Text {
                                        text: modelData.name || "App"
                                        color: ColorService.textPrimary
                                        font.family: Theme.fontMain
                                        font.pixelSize: 14
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: modelData.genericName || modelData.comment || modelData.execString || ""
                                        color: ColorService.textSecondary
                                        font.family: Theme.fontMain
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        visible: text.length > 0
                                        Layout.fillWidth: true
                                    }
                                }

                                Text {
                                    text: "󰅂"
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 16
                                    color: listItemArea.containsMouse ? ColorService.accent : "transparent"
                                    Layout.alignment: Qt.AlignVCenter
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                id: listItemArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        appCtxMenu.appData = modelData;
                                        appCtxMenu.popup();
                                        return;
                                    }
                                    launcherRoot.launchApp(modelData);
                                    launcherRoot.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Menu {
        id: appCtxMenu
        property var appData: null

        background: Rectangle {
            implicitWidth: 180
            color: ColorService.bgElevated
            radius: 16
            border.color: Qt.alpha(ColorService.accent, 0.2)
            border.width: 1
        }

        MenuItem {
            text: "Open"
            contentItem: Text {
                text: "Open"
                color: ColorService.textPrimary
                font.family: Theme.fontMain; font.pixelSize: 13; leftPadding: 12
            }
            background: Rectangle { color: parent.hovered ? Qt.alpha(ColorService.accent, 0.15) : "transparent"; radius: 10 }
            onTriggered: {
                launcherRoot.launchApp(appCtxMenu.appData);
                launcherRoot.close();
            }
        }
        MenuSeparator { contentItem: Rectangle { height: 1; color: Qt.rgba(1,1,1,0.08) } }
        MenuItem {
            text: {
                let d = appCtxMenu.appData;
                if (!d) return "Pin to shelf";
                let aid = (d.startupClass || d.id || d.name || "").replace(/\.desktop$/, "");
                return PinsService.isPinned(aid) ? "Unpin from shelf" : "Pin to shelf";
            }
            contentItem: Text {
                text: parent.text
                color: ColorService.textPrimary
                font.family: Theme.fontMain; font.pixelSize: 13; leftPadding: 12
            }
            background: Rectangle { color: parent.hovered ? Qt.alpha(ColorService.accent, 0.15) : "transparent"; radius: 10 }
            onTriggered: {
                let d = appCtxMenu.appData;
                if (!d) return;
                let aid = (d.startupClass || d.id || d.name || "").replace(/\.desktop$/, "");
                if (PinsService.isPinned(aid)) {
                    PinsService.unpin(aid);
                } else {
                    let cleanExec = (d.command && d.command.length > 0)
                        ? d.command.join(" ")
                        : (d.execString || d.exec || "").replace(/%[uUfFiick]/g, "").trim();
                    PinsService.pin(aid, d.name || aid, cleanExec || aid, d.icon || aid);
                }
            }
        }
    }
}
