import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

Item {
    id: root

    FileView {
        id: fileView
        path: Quickshell.env("HOME") + "/.config/quickshell/dock-settings.json"
        
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: dockAdapter
            property bool showUnpinned:         true
            property bool expressiveWorkspaces: true
            property int  barHeight:            64
            property int  dockIconSize:         26
            property bool showSeconds:          false
        }
    }

    property alias showUnpinned:         dockAdapter.showUnpinned
    property alias expressiveWorkspaces: dockAdapter.expressiveWorkspaces
    property alias barHeight:            dockAdapter.barHeight
    property alias dockIconSize:         dockAdapter.dockIconSize
    property alias showSeconds:          dockAdapter.showSeconds

    function save() {
        fileView.writeAdapter();
    }
}
