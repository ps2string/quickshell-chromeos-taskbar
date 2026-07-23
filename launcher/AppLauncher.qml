import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../services"

// ChromeOS-style app launcher / app drawer
// Opens bottom-left, shows pinned apps row + all-apps grid with search

PopupWindow {
    id: launcherRoot

    implicitWidth:  540
    implicitHeight: 620
    visible: false
    color: "transparent"
    grabFocus: true

    // Close on click-outside
    onVisibleChanged: if (visible) searchInput.forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(ColorService.bgBase.r, ColorService.bgBase.g, ColorService.bgBase.b, 0.96)
        radius: Theme.radiusLarge
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1

        layer.enabled: true
        layer.effect: null  // shadow handled by window compositor

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
                        Keys.onEscapePressed: launcherRoot.visible = false
                        onTextChanged: appGrid.currentFilter = searchInput.text
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
                                        visible: backer.status === Image.Ready
                                    }
                                    Rectangle {
                                        anchors.fill: parent; radius: 10
                                        color: ColorService.accentDim
                                        visible: pinnedIcon.backer.status !== Image.Ready
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
                                    launcherRoot.visible = false;
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

            // ---- All apps section label ----
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

            // ---- App grid ----
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                GridView {
                    id: appGrid
                    anchors.fill: parent
                    cellWidth: 100
                    cellHeight: 110
                    property string currentFilter: ""

                    model: {
                        let all = (typeof DesktopEntries !== "undefined" && DesktopEntries.applications && DesktopEntries.applications.values)
                            ? DesktopEntries.applications.values : [];
                        if (!currentFilter || currentFilter.trim() === "") return all;
                        let q = currentFilter.toLowerCase().trim();
                        return all.filter(app => {
                            if (!app) return false;
                            let n = (app.name || "").toLowerCase();
                            let g = (app.genericName || "").toLowerCase();
                            let e = (app.execString || app.exec || "").toLowerCase();
                            let id = (app.id || "").toLowerCase();
                            return n.includes(q) || g.includes(q) || e.includes(q) || id.includes(q);
                        });
                    }

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
                                        visible: backer.status === Image.Ready
                                        smooth: true
                                    }
                                    Rectangle {
                                        anchors.fill: parent; radius: 14
                                        color: ColorService.accentDim
                                        visible: gridIcon.backer.status !== Image.Ready
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
                                    if (modelData.execute) modelData.execute();
                                    else if (modelData.exec) {
                                        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', launcherRoot);
                                        p.command = ["sh", "-c", modelData.exec]; p.running = true;
                                    }
                                    launcherRoot.visible = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Context menu for app grid items
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
                let d = appCtxMenu.appData;
                if (d && d.execute) d.execute();
                else if (d && d.exec) {
                    let p = Qt.createQmlObject('import Quickshell.Io; Process {}', launcherRoot);
                    p.command = ["sh", "-c", d.exec]; p.running = true;
                }
                launcherRoot.visible = false;
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
