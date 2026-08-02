import Quickshell
import Quickshell.Io
import QtQuick

pragma Singleton

Item {
    id: root
    property var pins: []
    readonly property string _pinsFile: Quickshell.env("HOME") + "/.config/quickshell/pins.json"

    Process {
        id: saveProc
    }

    readonly property var _defaults: [
        { appId: "floorp",   name: "Floorp Browser", exec: "floorp",   icon: "floorp" },
        { appId: "kitty",    name: "Terminal",       exec: "kitty",    icon: "kitty" },
        { appId: "obsidian", name: "Obsidian",       exec: "obsidian", icon: "obsidian" }
    ]

    Process {
        id: loadProc
        command: ["cat", root._pinsFile]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt.length >= 2) {
                    root._parsePins(txt);
                } else {
                    root.pins = root._defaults;
                    root._save();
                }
            }
        }
    }

    function _parsePins(jsonText) {
        try {
            let arr = JSON.parse(jsonText);
            if (Array.isArray(arr)) {
                root.pins = arr;
            } else {
                root.pins = root._defaults;
            }
        } catch(e) {
            root.pins = root._defaults;
        }
    }

    function _save() {
        if (saveProc.running) return;
        let json = JSON.stringify(root.pins, null, 2);
        saveProc.command = ["bash", "-c", `printf '%s' '${json.replace(/'/g, "'\\''")}' > '${root._pinsFile}'`];
        saveProc.running = true;
    }

    function isPinned(appId) {
        if (!appId) return false;
        let id = appId.toLowerCase().replace(/\.desktop$/, "");
        return root.pins.some(p => {
            let pid = (p.appId || "").toLowerCase().replace(/\.desktop$/, "");
            let pexec = (p.exec || "").toLowerCase();
            return pid === id || pexec.includes(id);
        });
    }

    function pin(appId, name, exec, icon) {
        if (!isPinned(appId)) {
            let cleanExec  = (exec  || "").replace(/%[uUfFiick]/g, "").trim();
            let cleanAppId = (appId || "").replace(/\.desktop$/, "");
            let cleanIcon  = (icon  || cleanAppId).replace(/^image:\/\/icon\//, "");
            let updated = [...root.pins, { appId: cleanAppId, name: name || cleanAppId, exec: cleanExec || cleanAppId, icon: cleanIcon }];
            root.pins = updated;
            _save();
        }
    }

    function unpin(appId) {
        if (!appId) return;
        let id = appId.toLowerCase().replace(/\.desktop$/, "");
        root.pins = root.pins.filter(p => {
            let pid = (p.appId || "").toLowerCase().replace(/\.desktop$/, "");
            let pexec = (p.exec || "").toLowerCase();
            return pid !== id && !pexec.includes(id);
        });
        _save();
    }

    function reorderPin(fromIndex, toIndex) {
        if (fromIndex < 0 || fromIndex >= root.pins.length) return;
        if (toIndex < 0 || toIndex >= root.pins.length) return;
        if (fromIndex === toIndex) return;

        let newPins = [...root.pins];
        let item = newPins.splice(fromIndex, 1)[0];
        newPins.splice(toIndex, 0, item);
        root.pins = newPins;
        _save();
    }
}
