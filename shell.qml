import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "bar"
import "launcher"
import "quicksettings"
import "services"

Scope {
    id: root

    Variants {
        model: Quickshell.screens
        delegate: Component {
            Scope {
                id: screenScope

                required property var modelData
                property var currentScreen: modelData

                // IPC handler for start menu / launcher toggle
                IpcHandler {
                    target: "launcher"

                    function toggle() {
                        let focusedName = (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) ? Hyprland.focusedMonitor.name : "";
                        if (focusedName === "" || currentScreen.name === focusedName || Quickshell.screens.length === 1) {
                            appLauncher.visible = !appLauncher.visible;
                            if (appLauncher.visible) quickSettings.visible = false;
                        } else {
                            appLauncher.visible = false;
                        }
                    }

                    function open() {
                        let focusedName = (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) ? Hyprland.focusedMonitor.name : "";
                        if (focusedName === "" || currentScreen.name === focusedName || Quickshell.screens.length === 1) {
                            appLauncher.visible = true;
                            quickSettings.visible = false;
                        } else {
                            appLauncher.visible = false;
                        }
                    }

                    function close() {
                        appLauncher.visible = false;
                    }
                }

                // Hyprland GlobalShortcut support
                GlobalShortcut {
                    name: "launcher"
                    description: "Toggle Start Menu"
                    onPressed: {
                        let focusedName = (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) ? Hyprland.focusedMonitor.name : "";
                        if (focusedName === "" || currentScreen.name === focusedName || Quickshell.screens.length === 1) {
                            appLauncher.visible = !appLauncher.visible;
                            if (appLauncher.visible) quickSettings.visible = false;
                        } else {
                            appLauncher.visible = false;
                        }
                    }
                }

                BottomBar {
                    id: mainBar
                    screen: screenScope.currentScreen

                    onToggleLauncher: {
                        appLauncher.visible = !appLauncher.visible;
                        if (appLauncher.visible) quickSettings.visible = false;
                    }

                    onToggleQuickSettings: {
                        quickSettings.visible = !quickSettings.visible;
                        if (quickSettings.visible) appLauncher.visible = false;
                    }

                    onRequestShelfContextMenu: (itemData, posX) => {
                        shelfContextMenu.itemData = itemData;
                        let targetX = Math.round(posX - shelfContextMenu.implicitWidth / 2);
                        shelfContextMenu.popupX = Math.max(8, Math.min(mainBar.width - shelfContextMenu.implicitWidth - 8, targetX));
                        shelfContextMenu.visible = true;
                    }
                }

                // OSD popup — centered at bottom, above shelf
                Connections {
                    target: SystemService
                    function onShowOsd(icon, title, val, muted) {
                        osdPopup.showOsd(icon, title, val, muted);
                    }
                }

                OsdPopup {
                    id: osdPopup
                    anchor {
                        window: mainBar
                        rect {
                            x: Math.round((mainBar.width - osdPopup.implicitWidth) / 2)
                            y: Math.round(-osdPopup.implicitHeight - 16)
                            width: Math.round(osdPopup.implicitWidth)
                            height: Math.round(osdPopup.implicitHeight)
                        }
                    }
                }

                ShelfContextMenu {
                    id: shelfContextMenu

                    anchor {
                        window: mainBar
                        rect {
                            x: shelfContextMenu.popupX
                            y: Math.round(-shelfContextMenu.implicitHeight - 8)
                            width: Math.round(shelfContextMenu.implicitWidth)
                            height: Math.round(shelfContextMenu.implicitHeight)
                        }
                    }
                }

                AppLauncher {
                    id: appLauncher

                    anchor {
                        window: mainBar
                        rect {
                            x: 8
                            y: Math.round(-appLauncher.implicitHeight - 8)
                            width: Math.round(appLauncher.implicitWidth)
                            height: Math.round(appLauncher.implicitHeight)
                        }
                    }
                }

                QuickSettings {
                    id: quickSettings

                    anchor {
                        window: mainBar
                        rect {
                            x: Math.round(mainBar.width - quickSettings.implicitWidth - 8)
                            y: Math.round(-quickSettings.implicitHeight - 8)
                            width: Math.round(quickSettings.implicitWidth)
                            height: Math.round(quickSettings.implicitHeight)
                        }
                    }
                }
            }
        }
    }
}
