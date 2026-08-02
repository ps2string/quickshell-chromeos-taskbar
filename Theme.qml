import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

Item {
    id: root

    readonly property int radiusSmall:  8
    readonly property int radiusMedium: 16
    readonly property int radiusLarge:  24
    readonly property int radiusPill:   999

    FileView {
        id: fileView
        path: Quickshell.env("HOME") + "/.config/quickshell/theme-settings.json"
        
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: themeAdapter
            property string fontMain: "SF Pro Rounded"
            property string fontIcon: "JetBrainsMono Nerd Font"
            property real uiScale: 1.0
        }
    }

    property alias fontMain: themeAdapter.fontMain
    property alias fontIcon: themeAdapter.fontIcon
    property alias uiScale: themeAdapter.uiScale

    function save() {
        fileView.writeAdapter();
    }
}
