import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire as Pw
import QtQuick

pragma Singleton

Item {
    id: root

    property int    brightness:    70
    property int    batteryLevel:  100
    property bool   isCharging:    false
    property string batteryTime:   ""
    property string wifiSsid:      "Disconnected"
    property bool   wifiConnected: false  
    property bool   wifiEnabled:   false  
    
    readonly property bool bluetoothOn: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
    readonly property bool isScanningBt: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.discovering : false
    readonly property var  bluetoothDevices: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.devices : null
    
    property bool   dndActive:     false
    property bool   nightLightOn:  false

    readonly property string _nightLightShader: Qt.resolvedUrl("../../hypr/modules/shaders/nightlight.glsl").toString().replace("file://", "")

    signal showOsd(string icon, string title, real val, bool muted)
    signal wifiConnectResult(bool success, string message)

    property var  wifiNetworks:      []
    property bool isScanningWifi:    false
    property bool isConnectingWifi:  false

    Pw.PwObjectTracker {
        id: pwTracker
        objects: [
            Pw.Pipewire.defaultAudioSink,
            Pw.Pipewire.defaultAudioSource
        ]
    }

    readonly property var activeSink: Pw.Pipewire.defaultAudioSink
    readonly property var activeSource: Pw.Pipewire.defaultAudioSource

    property int volume: activeSink && activeSink.audio ? Math.round(activeSink.audio.volume * 100) : 0
    property bool isMuted: activeSink && activeSink.audio ? activeSink.audio.muted : false

    function getNodeLabel(node) {
        if (!node) return "Unknown Device";

        if (node.description && String(node.description).trim().length > 0) {
            return String(node.description).trim();
        }
        if (node.nick && String(node.nick).trim().length > 0) {
            return String(node.nick).trim();
        }
        if (node.name && String(node.name).trim().length > 0) {
            return String(node.name).trim();
        }

        if (node.properties) {
            try {
                let p = node.properties;
                let desc = p["node.description"] || p["device.description"] || p["node.nick"] || p["media.name"] || p["node.name"];
                if (desc && String(desc).trim().length > 0) {
                    return String(desc).trim();
                }
            } catch (e) {}
        }

        return "Audio Device (" + (node.id !== undefined ? node.id : "?") + ")";
    }

    readonly property var audioOutputs: {
        let outputs = [];
        if (!Pw.Pipewire.ready) return outputs;
        
        let nodes = Pw.Pipewire.nodes.values;
        for (let i = 0; i < nodes.length; i++) {
            let node = nodes[i];
            if (node && node.audio && !node.isStream && node.isSink) {
                outputs.push({
                    deviceId: node.id,
                    deviceLabel: root.getNodeLabel(node),
                    inUse: activeSink && (activeSink.id === node.id),
                    rawNode: node
                });
            }
        }
        return outputs;
    }

    readonly property var audioInputs: {
        let inputs = [];
        if (!Pw.Pipewire.ready) return inputs;
        
        let nodes = Pw.Pipewire.nodes.values;
        for (let i = 0; i < nodes.length; i++) {
            let node = nodes[i];
            if (node && node.audio && !node.isStream && !node.isSink) {
                inputs.push({
                    deviceId: node.id,
                    deviceLabel: root.getNodeLabel(node),
                    inUse: activeSource && (activeSource.id === node.id),
                    rawNode: node
                });
            }
        }
        return inputs;
    }

    property int _lastVolume: -1
    property bool _lastMuted: false

    onVolumeChanged: {
        if (_lastVolume >= 0 && (volume !== _lastVolume || isMuted !== _lastMuted)) {
            let icon = isMuted ? "󰖁" : (volume > 60 ? "󰕾" : (volume > 0 ? "󰖀" : "󰕿"));
            root.showOsd(icon, "Volume", volume, isMuted);
        }
        _lastVolume = volume;
        _lastMuted = isMuted;
    }

    function setVolume(val) {
        if (activeSink && activeSink.audio) {
            activeSink.audio.volume = Math.max(0, Math.min(100, Math.round(val))) / 100.0;
        }
    }

    function toggleMute() {
        if (activeSink && activeSink.audio) {
            activeSink.audio.muted = !activeSink.audio.muted;
        }
    }

    function setAudioOutput(nodeObj) {
        let targetNode = nodeObj.rawNode || nodeObj;
        if (targetNode) {
            Pw.Pipewire.preferredDefaultAudioSink = targetNode;
        }
    }

    function setAudioInput(nodeObj) {
        let targetNode = nodeObj.rawNode || nodeObj;
        if (targetNode) {
            Pw.Pipewire.preferredDefaultAudioSource = targetNode;
        }
    }

    property int _lastBrightness:  -1
    property int _maxBrightness:   19200

    Process {
        id: brightGet
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split(",");
                if (parts.length >= 4) {
                    let pct = parseInt(parts[3].replace("%", ""));
                    if (!isNaN(pct)) {
                        let changed = pct !== root._lastBrightness;
                        root.brightness = pct;
                        if (root._lastBrightness >= 0 && changed) {
                            let icon = pct > 60 ? "󰃠" : (pct > 30 ? "󰃟" : "󰃞");
                            root.showOsd(icon, "Brightness", pct, false);
                        }
                        root._lastBrightness = pct;
                    }
                }
            }
        }
    }

    Timer {
        id: brightPollTimer
        interval: 200
        running: true
        repeat: true
        onTriggered: brightGet.running = true
    }

    Process {
        id: batGet
        command: ["cat", "/sys/class/power_supply/BAT0/capacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(this.text.trim());
                if (!isNaN(val)) root.batteryLevel = val;
            }
        }
    }
    Process {
        id: batStatus
        command: ["cat", "/sys/class/power_supply/BAT0/status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.isCharging = (this.text.trim() === "Charging");
            }
        }
    }

    Process {
        id: batTimeGet
        command: ["bash", "-c",
            "if command -v upower >/dev/null 2>&1; then " +
                "t=$(upower -i $(upower -e | grep -i 'BAT' | head -n1) 2>/dev/null | grep -E 'time to (empty|full)' | awk -F':' '{print $2}' | xargs); " +
                "if [ -n \"$t\" ]; then echo \"$t\"; exit 0; fi; " +
            "fi; " +
            "if command -v acpi >/dev/null 2>&1; then " +
                "t=$(acpi -b 2>/dev/null | grep -oP '\\d{2}:\\d{2}' | head -n1); " +
                "if [ -n \"$t\" ]; then " +
                    "h=$(echo $t | cut -d: -f1 | sed 's/^0//'); " +
                    "m=$(echo $t | cut -d: -f2 | sed 's/^0//'); " +
                    "if [ \"$h\" != \"0\" ] && [ -n \"$h\" ]; then echo \"${h}h ${m}m\"; else echo \"${m}m\"; fi; " +
                "fi; " +
            "fi"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.batteryTime = this.text.trim();
            }
        }
    }

    Process {
        id: wifiGet
        command: ["bash", "-c",
            "radio=$(nmcli -t -f WIFI radio | head -1); " +
            "nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null; " +
            "echo \"__RADIO__$radio\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split("\n");
                let found = false;
                let radioEnabled = true;
                for (let line of lines) {
                    if (line.startsWith("__RADIO__")) {
                        radioEnabled = line.substring(9).trim() !== "disabled";
                    } else if (line.startsWith("yes:")) {
                        root.wifiSsid = line.substring(4).trim();
                        root.wifiConnected = true;
                        found = true;
                    }
                }
                root.wifiEnabled = radioEnabled;
                if (!found) {
                    root.wifiConnected = false;
                    if (!radioEnabled) {
                        root.wifiSsid = "Disconnected";
                    } else {
                        root.wifiSsid = "Not connected";
                    }
                }
            }
        }
    }

    Process {
        id: wifiScanProc
        command: ["bash", "-c",
            "nmcli dev wifi rescan 2>/dev/null; " +
            "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split("\n");
                let list = [];
                let seen = {};
                for (let line of lines) {
                    let idx0 = line.indexOf(":");
                    if (idx0 < 0) continue;
                    let idx1 = line.indexOf(":", idx0 + 1);
                    if (idx1 < 0) continue;
                    let idx2 = line.indexOf(":", idx1 + 1);

                    let inUse    = line.substring(0, idx0).trim() === "*";
                    let ssid     = line.substring(idx0 + 1, idx1).trim();
                    let signal   = parseInt(line.substring(idx1 + 1, idx2 >= 0 ? idx2 : undefined)) || 0;
                    let security = idx2 >= 0 ? line.substring(idx2 + 1).trim() : "";

                    if (ssid.length > 0 && !seen[ssid]) {
                        seen[ssid] = true;
                        list.push({ inUse: inUse, ssid: ssid, signal: signal, security: security });
                    }
                }
                list.sort((a, b) => (b.inUse ? 1 : 0) - (a.inUse ? 1 : 0) || (b.signal - a.signal));
                root.wifiNetworks = list;
                root.isScanningWifi = false;
                wifiGet.running = true;
            }
        }
    }

    Process {
        id: wifiConnectProc
        property string _targetSsid: ""
        stdout: StdioCollector { id: wifiConnectStdout }
        stderr: StdioCollector { id: wifiConnectStderr }
        onRunningChanged: {
            if (!running) {
                let out = wifiConnectStdout.text.trim();
                let err = wifiConnectStderr.text.trim();
                let combined = (out + " " + err).trim();

                let ok = exitCode === 0 || combined.toLowerCase().includes("successfully activated");

                let msg = "";
                if (ok) {
                    msg = "Connected to " + wifiConnectProc._targetSsid;
                } else {
                    let errLine = err.length > 0 ? err : out;
                    let match = errLine.match(/Error:\s*(.+)/i);
                    msg = match ? match[1].trim() : (errLine.length > 0 ? errLine : "Connection failed");
                    if (msg.length > 80) msg = msg.substring(0, 80) + "…";
                }

                root.isConnectingWifi = false;
                root.wifiConnectResult(ok, msg);
                wifiGet.running = true;
                if (ok) {
                    wifiRefreshTimer.start();
                }
            }
        }
    }

    Timer {
        id: wifiRefreshTimer
        interval: 1500
        repeat: false
        onTriggered: {
            root.isScanningWifi = true;
            wifiScanProc.running = true;
        }
    }

    Process { id: setBrightProc }
    Process { id: setWifiProc }
    Process { id: setNightLightProc }

    Process {
        id: nightLightGetProc
        command: ["bash", "-c", "pgrep -x hyprsunset >/dev/null && echo 'on' || echo 'off'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.nightLightOn = (this.text.trim() === "on");
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        nightLightGetProc.running = true;
    }

    function refresh() {
        batGet.running            = true;
        batStatus.running         = true;
        batTimeGet.running        = true;
        wifiGet.running           = true;
        nightLightGetProc.running = true;
    }

    function setBrightness(val) {
        root.brightness = Math.max(5, Math.min(100, Math.round(val)));
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["brightnessctl", "s", root.brightness + "%"];
        p.running = true;
    }

    function toggleWifi() {
        let turnOn = !root.wifiEnabled;
        setWifiProc.command = ["nmcli", "radio", "wifi", turnOn ? "on" : "off"];
        setWifiProc.running = true;
        root.wifiEnabled = turnOn;
        if (!turnOn) {
            root.wifiConnected = false;
            root.wifiSsid = "Disconnected";
            root.wifiNetworks = [];
        }
    }

    function scanWifi() {
        if (!root.wifiEnabled) {
            setWifiProc.command = ["nmcli", "radio", "wifi", "on"];
            setWifiProc.running = true;
            root.wifiEnabled = true;
        }
        root.isScanningWifi = true;
        wifiScanProc.running = true;
    }

    function connectWifi(ssid, password) {
        if (root.isConnectingWifi) return;
        root.isConnectingWifi = true;
        wifiConnectProc._targetSsid = ssid;
        if (password && password.length > 0) {
            wifiConnectProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
        } else {
            wifiConnectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
        }
        wifiConnectProc.running = true;
    }

    function toggleBluetooth() {
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
        }
    }

    function scanBluetooth() {
        if (Bluetooth.defaultAdapter) {
            if (!Bluetooth.defaultAdapter.enabled) {
                Bluetooth.defaultAdapter.enabled = true;
            }
            Bluetooth.defaultAdapter.discovering = true;
        }
    }

    function toggleDnd() {
        root.dndActive = !root.dndActive;
    }

    function toggleNightLight() {
        let turnOn = !root.nightLightOn;
        root.nightLightOn = turnOn;

        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        if (turnOn) {
            p.command = ["bash", "-c", "pkill -x hyprsunset 2>/dev/null; nohup hyprsunset -t 4500 >/dev/null 2>&1 &"];
        } else {
            p.command = ["bash", "-c", "pkill -9 -x hyprsunset 2>/dev/null; pkill -x hyprsunset 2>/dev/null"];
        }
        p.running = true;

        let t = Qt.createQmlObject('import QtQuick; Timer { interval: 600; repeat: false }', root);
        t.triggered.connect(() => { nightLightGetProc.running = true; });
        t.start();
    }

    function powerOff() {
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["systemctl", "poweroff"]; p.running = true;
    }

    function reboot() {
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["systemctl", "reboot"]; p.running = true;
    }

    function lockScreen() {
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["hyprlock"]; p.running = true;
    }

    function logout() {
        Quickshell.execDetached(["hyprshutdown"]);
    }
}
