import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../services"

// ChromeOS-style app launcher / app drawer
// Opens bottom-left, shows pinned apps row + all-apps grid (or list view on search)

PopupWindow {
    id: launcherRoot

    implicitWidth:  540
    implicitHeight: 620
    visible: false
    color: "transparent"
    grabFocus: true

    property bool isOpen: false

    // Launch helper function
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

    // Safely retrieve and filter application list
    function getFilteredApps() {
        let all = [];
        if (typeof DesktopEntries !== "undefined" && DesktopEntries.applications && DesktopEntries.applications.values) {
            let vals = DesktopEntries.applications.values;
            for (let i = 0; i < vals.length; i++) {
                if (vals[i]) all.push(vals[i]);
            }
        }
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

    // Launch top search result
    function launchFirstResult() {
        let results = getFilteredApps();
        if (results.length > 0) {
            launchApp(results[0]);
            close();
        }
    }

    // Control functions
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

    // Timer to allow slide-down animation to finish before hiding window
    Timer {
        id: closeTimer
        interval: 250
        repeat: false
        onTriggered: {
            visible = false;
            searchInput.text = "";
        }
    }

    // Catch external visibility toggles
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
        color: Qt.alpha(ColorService.bgBase, 0.96)
        radius: Theme.radiusLarge
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1

        layer.enabled: true
        layer.effect: null

        // ChromeOS Slide & Fade Animations
        opacity: launcherRoot.isOpen ? 1.0 : 0.0
        transform: Translate {
            y: launcherRoot.isOpen ? 0 : 40
            Behavior on y {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Behavior on color { ColorAnimation { duration: 400 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // ---- Search bar ----
            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: Theme.radiusPill
                color: ColorService.bgSurface
                border.color: searchInput.activeFocus ? ColorService.accent : Qt.rgba(1,1,1,0.08)
                border.width: 2

                Behavior on color        { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Text {
                        text: ""
                        font.family: Theme.fontIcon
                        font.pixelSize: 16
                        color: searchInput.activeFocus ? ColorService.accent : ColorService.textSecondary
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        placeholderText: "Search apps…"
                        placeholderTextColor: ColorService.textSecondary
                        color: ColorService.textPrimary
                        font.family: Theme.fontMain
                        font.pixelSize: 15
                        background: null
                        Keys.onEscapePressed: launcherRoot.close()
                        Keys.onReturnPressed: launcherRoot.launchFirstResult()
                        Keys.onEnterPressed: launcherRoot.launchFirstResult()
                    }

                    // Clear button
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: clearArea.containsMouse ? ColorService.bgHover : "transparent"
                        visible: searchInput.text.length > 0
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: Theme.fontIcon
                            font.pixelSize: 12
                            color: ColorService.textSecondary
                        }
                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: searchInput.text = ""
                        }
                    }
                }
            }

            // ---- Pinned / Recent section label ----
            Text {
                visible: searchInput.text.length === 0
                text: "Pinned"
                color: ColorService.textSecondary
                font.family: Theme.fontMain
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 0.8
                leftPadding: 4
            }

            // ---- Pinned apps quick row ----
            Row {
                visible: searchInput.text.length === 0
                spacing: 6
                Repeater {
                    model: PinsService.pins.slice(0, 6)
                    delegate: Item {
                        width: 72; height: 72
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: Theme.radiusMedium
                            color: pinnedArea.containsMouse ? ColorService.bgHover : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 36; height: 36; radius: 10
                                    color: "transparent"

                                    IconImage {
                                        id: pinnedIcon
                                        anchors.fill: parent
                                        source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                                        visible: status === Image.Ready
                                    }
                                    Rectangle {
                                        anchors.fill: parent; radius: 10
                                        color: ColorService.accentDim
                                        visible: pinnedIcon.status !== Image.Ready
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.name ? modelData.name[0].toUpperCase() : "?"
                                            color: ColorService.accent; font.bold: true; font.pixelSize: 16
                                        }
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.maximumWidth: 68
                                    text: modelData.name || "App"
                                    color: ColorService.textPrimary
                                    font.family: Theme.fontMain
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
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
                }
            }

            // Divider
            Rectangle {
                visible: searchInput.text.length === 0
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.07)
            }

            // ---- Section label ----
            Text {
                text: searchInput.text.length === 0 ? "All apps" : ("Results for \"" + searchInput.text + "\"")
                color: ColorService.textSecondary
                font.family: Theme.fontMain
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 0.8
                leftPadding: 4
                Behavior on color { ColorAnimation { duration: 400 } }
            }

            // ---- Content Container (Grid for default, List for Search) ----
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                // --- Grid View (Default "All Apps") ---
                GridView {
                    id: appGrid
                    anchors.fill: parent
                    visible: searchInput.text.length === 0
                    cellWidth: 100
                    cellHeight: 110

                    model: searchInput.text.length === 0 ? launcherRoot.getFilteredApps() : []

                    delegate: Item {
                        width: appGrid.cellWidth
                        height: appGrid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: Theme.radiusMedium
                            color: gridItemArea.containsMouse ? ColorService.bgHover : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                // Icon frame
                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 52; height: 52
                                    radius: 14
                                    color: "transparent"

                                    IconImage {
                                        id: gridIcon
                                        anchors.fill: parent
                                        source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                                        visible: status === Image.Ready
                                        smooth: true
                                    }
                                    Rectangle {
                                        anchors.fill: parent; radius: 14
                                        color: ColorService.accentDim
                                        visible: gridIcon.status !== Image.Ready
                                        Behavior on color { ColorAnimation { duration: 400 } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.name ? modelData.name[0].toUpperCase() : "A"
                                            color: ColorService.accent
                                            font.family: Theme.fontMain
                                            font.pixelSize: 22
                                            font.bold: true
                                        }
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.maximumWidth: 88
                                    text: modelData.name || "App"
                                    color: ColorService.textPrimary
                                    font.family: Theme.fontMain
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    Behavior on color { ColorAnimation { duration: 400 } }
                                }
                            }

                            MouseArea {
                                id: gridItemArea
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

                // --- List View (Used when searching) ---
                ListView {
                    id: appList
                    anchors.fill: parent
                    visible: searchInput.text.length > 0
                    spacing: 4

                    model: searchInput.text.length > 0 ? launcherRoot.getFilteredApps() : []

                    delegate: Item {
                        width: appList.width
                        height: 52

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: Theme.radiusMedium
                            color: listItemArea.containsMouse ? ColorService.bgHover : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 14

                                // Icon
                                Rectangle {
                                    width: 36; height: 36
                                    radius: 10
                                    color: "transparent"
                                    Layout.alignment: Qt.AlignVCenter

                                    IconImage {
                                        id: listIcon
                                        anchors.fill: parent
                                        source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                                        visible: status === Image.Ready
                                        smooth: true
                                    }
                                    Rectangle {
                                        anchors.fill: parent; radius: 10
                                        color: ColorService.accentDim
                                        visible: listIcon.status !== Image.Ready
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.name ? modelData.name[0].toUpperCase() : "A"
                                            color: ColorService.accent
                                            font.family: Theme.fontMain
                                            font.pixelSize: 16
                                            font.bold: true
                                        }
                                    }
                                }

                                // App Name & Description
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

    // Context menu for app items
    Menu {
        id: appCtxMenu
        property var appData: null

        background: Rectangle {
            implicitWidth: 180
            color: ColorService.bgElevated
            radius: 12
            border.color: Qt.rgba(1,1,1,0.12)
            border.width: 1
        }

        MenuItem {
            text: "Open"
            contentItem: Text {
                text: "Open"
                color: ColorService.textPrimary
                font.family: Theme.fontMain; font.pixelSize: 13; leftPadding: 12
            }
            background: Rectangle { color: parent.hovered ? ColorService.bgHover : "transparent"; radius: 8 }
            onTriggered: {
                launcherRoot.launchApp(appCtxMenu.appData);
                launcherRoot.close();
            }
        }
        MenuSeparator { contentItem: Rectangle { height: 1; color: Qt.rgba(1,1,1,0.1) } }
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
            background: Rectangle { color: parent.hovered ? ColorService.bgHover : "transparent"; radius: 8 }
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
