import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../services"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors { top: true; bottom: true; left: true; right: true }

    // Fully transparent root – no dark overlay
    color: "transparent"
    visible: false

    property string currentCategory: "sound"

    onVisibleChanged: {
        if (!visible) {
            // Deactivate the loader to free resources and reset view state
            viewLoader.active = false;
        } else {
            viewLoader.active = true;
        }
    }

    // Backdrop click dismisses window
    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.visible = false

        // Centered Window Card
        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(parent.width - 48, 920)
            height: Math.min(parent.height - 48, 620)
            color: Qt.rgba(
                ColorService.bgElevated.r,
                ColorService.bgElevated.g,
                ColorService.bgElevated.b,
                0.98
            )
            radius: 28
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1

            // Entrance animation
            property bool _ready: false
            Component.onCompleted: _ready = true
            opacity: root.visible ? 1.0 : 0.0
            scale: root.visible ? 1.0 : 0.96
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on scale  { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            // Consume click events so backdrop doesn't dismiss on card click
            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => mouse.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // --- Top Header ---
                RowLayout {
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 10
                        Layout.fillWidth: true

                        Text {
                            text: "󰒓"
                            font.family: Theme.fontIcon
                            font.pixelSize: 20
                            color: ColorService.accent
                        }

                        Text {
                            text: "Settings"
                            font.family: Theme.fontMain
                            font.pixelSize: 16
                            font.bold: true
                            color: ColorService.textPrimary
                        }

                        Text {
                            text: "·"
                            font.family: Theme.fontMain
                            font.pixelSize: 14
                            color: ColorService.textSecondary
                        }

                        Text {
                            text: getCategoryTitle(root.currentCategory)
                            font.family: Theme.fontMain
                            font.pixelSize: 14
                            color: ColorService.textSecondary
                            elide: Text.ElideRight
                        }

                        Item { Layout.fillWidth: true }

                        // Close button
                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: closeMa.containsMouse
                                ? Qt.rgba(1, 1, 1, 0.12)
                                : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: Theme.fontIcon
                                font.pixelSize: 14
                                color: ColorService.textSecondary
                            }
                            MouseArea {
                                id: closeMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.visible = false
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.07)
                }

                // --- Main Body Layout ---
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    // Sidebar Navigation
                    ColumnLayout {
                        Layout.fillWidth: false
                        Layout.preferredWidth: 210
                        Layout.maximumWidth: 210
                        Layout.fillHeight: true
                        spacing: 2

                        // Use a plain ColumnLayout inside a ScrollView for nav items
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: availableWidth
                            clip: true
                            // Disable the scrollbar flicker on hover
                            ScrollBar.vertical.policy: ScrollBar.AsNeeded
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            ColumnLayout {
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: [
                                        { id: "sound",      name: "Sound & Display",  icon: "󰕾" },
                                        { id: "network",    name: "Network & Wi-Fi",  icon: "󰤨" },
                                        { id: "bluetooth",  name: "Bluetooth",        icon: "󰂯" },
                                        { id: "wallpaper",  name: "Wallpaper",        icon: "󰸉" },
                                        { id: "hyprland",   name: "Hyprland",         icon: "󰋋" },
                                        { id: "power",      name: "Power",            icon: "󰐥" },
                                        { id: "dock",       name: "Bar & Dock",       icon: "󰅀" },
                                        { id: "typography", name: "Typography",       icon: "󰬴" },
                                        { id: "about",      name: "About System",     icon: "󰋼" }
                                    ]

                                    delegate: Rectangle {
                                        required property var modelData

                                        readonly property string idName: modelData.id
                                        readonly property string name: modelData.name
                                        readonly property string icon: modelData.icon
                                        readonly property bool isSelected: root.currentCategory === idName

                                        Layout.fillWidth: true
                                        height: 44
                                        radius: 12

                                        color: isSelected
                                            ? Qt.rgba(ColorService.accent.r, ColorService.accent.g, ColorService.accent.b, 0.18)
                                            : (navMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

                                        border.color: isSelected ? Qt.alpha(ColorService.accent, 0.35) : "transparent"
                                        border.width: isSelected ? 1 : 0

                                        // Simple color transitions (lighter = faster on N4020)
                                        Behavior on color { ColorAnimation { duration: 100 } }

                                        // Active indicator bar
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: 4
                                            width: 3
                                            height: isSelected ? 20 : 0
                                            radius: 2
                                            color: ColorService.accent
                                            Behavior on height {
                                                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                            }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 10
                                            spacing: 12

                                            Text {
                                                text: icon
                                                font.family: Theme.fontIcon
                                                font.pixelSize: 16
                                                color: isSelected ? ColorService.accent : ColorService.textSecondary
                                            }

                                            Text {
                                                text: name
                                                font.family: Theme.fontMain
                                                font.pixelSize: 13
                                                font.bold: isSelected
                                                color: isSelected ? ColorService.accent : ColorService.textPrimary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        MouseArea {
                                            id: navMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.currentCategory = idName
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        width: 1
                        color: Qt.rgba(1, 1, 1, 0.07)
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                    }

                    // Dynamic View Area
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Loader {
                            id: viewLoader
                            anchors.fill: parent
                            // active is controlled by onVisibleChanged
                            active: root.visible
                            source: {
                                switch (root.currentCategory) {
                                    case "network":    return "NetworkView.qml";
                                    case "bluetooth":  return "BluetoothView.qml";
                                    case "sound":      return "SoundDisplayView.qml";
                                    case "wallpaper":  return "WallpaperView.qml";
                                    case "hyprland":   return "HyprlandView.qml";
                                    case "power":      return "PowerView.qml";
                                    case "dock":       return "DockView.qml";
                                    case "typography": return "TypographyView.qml";
                                    case "about":      return "AboutView.qml";
                                    default:           return "SoundDisplayView.qml";
                                }
                            }

                            // Fast fade transition
                            opacity: status === Loader.Ready ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }
                    }
                }
            }
        }
    }

    function getCategoryTitle(cat) {
        switch(cat) {
            case "network":    return "Network & Wi-Fi";
            case "bluetooth":  return "Bluetooth";
            case "sound":      return "Sound & Display";
            case "wallpaper":  return "Wallpaper & Theme";
            case "hyprland":   return "Hyprland";
            case "power":      return "Power";
            case "dock":       return "Bar & Dock";
            case "typography": return "Typography";
            case "about":      return "About System";
            default:           return cat;
        }
    }
}
