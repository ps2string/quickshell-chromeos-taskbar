import Quickshell
import Quickshell.Io
import QtQuick

pragma Singleton

Item {
    id: root

    // --- State ---
    property int    volume:        50
    property bool   isMuted:       false
    property int    brightness:    70
    property int    batteryLevel:  100
    property bool   isCharging:    false
    property string wifiSsid:      "Disconnected"
    property bool   wifiConnected: false
    property bool   wifiEnabled:   false 
    property bool   bluetoothOn:   true
    property bool   dndActive:     false
    property bool   nightLightOn:  false

    readonly property string _nightLightShader: Qt.resolvedUrl("../../hypr/modules/shaders/nightlight.glsl").toString().replace("file://", "")

    signal showOsd(string icon, string title, real val, bool muted)
    signal wifiConnectResult(bool success, string message)

    property var  wifiNetworks:      []
    property bool isScanningWifi:    false
    property bool isConnectingWifi:  false

    property var  bluetoothDevices: []
    property bool isScanningBt:     false

    property int _lastVolume:      -1
    property bool _lastMuted:       false
    property int _lastBrightness:  -1
    property int _maxBrightness:   19200

    Process {
        id: volGet
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text.trim();
                let parts = text.split(/\s+/);
                if (parts.length >= 2) {
                    let newVol = Math.round(parseFloat(parts[1]) * 100);
                    let newMuted = text.includes("[MUTED]");
                    let changed = (newVol !== root._lastVolume || newMuted !== root._lastMuted);
                    root.volume = newVol;
                    root.isMuted = newMuted;
                    if (root._lastVolume >= 0 && changed) {
                        let icon = newMuted ? "󰖁" : (newVol > 60 ? "󰕾" : (newVol > 0 ? "󰖀" : "󰕿"));
                        root.showOsd(icon, "Volume", newVol, newMuted);
                    }
                    root._lastVolume = newVol;
                    root._lastMuted  = newMuted;
                }
            }
        }
    }

    Timer {
        id: volPollTimer
        interval: 200
        running: true
        repeat: true
        onTriggered: volGet.running = true
    }

    Process {
        id: brightGet
        command: ["cat", "/sys/class/backlight/intel_backlight/actual_brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = parseInt(this.text.trim());
                if (!isNaN(raw) && root._maxBrightness > 0) {
                    let pct = Math.round((raw / root._maxBrightness) * 100);
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

    Process {
        id: btCheck
        command: ["bash", "-c", "rfkill list bluetooth | grep -q 'Soft blocked: no' && echo 'on' || echo 'off'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { root.bluetoothOn = this.text.trim() === "on"; }
        }
    }

    Process {
        id: btScanProc
        command: ["bash", "-c", "bluetoothctl devices | while read -r line; do mac=$(echo \"$line\" | awk '{print $2}'); name=$(echo \"$line\" | cut -d' ' -f3-); info=$(bluetoothctl info \"$mac\" 2>/dev/null); conn=$(echo \"$info\" | grep -q 'Connected: yes' && echo 'true' || echo 'false'); echo \"$mac|$name|$conn\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                let list = [];
                for (let line of lines) {
                    let parts = line.split("|");
                    if (parts.length >= 3) {
                        let mac = parts[0].trim();
                        let name = parts[1].trim();
                        let conn = parts[2].trim() === "true";
                        if (mac.length > 0 && name.length > 0) {
                            list.push({ mac: mac, name: name, connected: conn });
                        }
                    }
                }
                list.sort((a, b) => (b.connected ? 1 : 0) - (a.connected ? 1 : 0));
                root.bluetoothDevices = list;
                root.isScanningBt = false;
            }
        }
    }

    Process { id: setVolProc }
    Process { id: setBrightProc }
    Process { id: setWifiProc }
    Process { id: setBtProc }
    Process { id: setNightLightProc }

    Process {
        id: dndGetProc
        command: ["swaync-client", "--get-dnd"]
        stdout: StdioCollector {
            onStreamFinished: {
                let val = this.text.trim().toLowerCase();
                root.dndActive = (val === "true");
            }
        }
    }

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
        dndGetProc.running = true;
        nightLightGetProc.running = true;
    }

    function refresh() {
        volGet.running            = true;
        batGet.running            = true;
        batStatus.running         = true;
        wifiGet.running           = true;
        btCheck.running           = true;
        dndGetProc.running        = true; 
        nightLightGetProc.running = true; 
    }

    function setVolume(val) {
        // volume OSD fires automatically via volPollTimer detecting the change
        root.volume = Math.max(0, Math.min(100, Math.round(val)));
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (root.volume / 100.0).toFixed(2)];
        p.running = true;
    }

    function toggleMute() {
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
        p.running = true;
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
        let action = root.bluetoothOn ? "block" : "unblock";
        setBtProc.command = ["rfkill", action, "bluetooth"];
        setBtProc.running = true;
        root.bluetoothOn = !root.bluetoothOn;
    }

    function scanBluetooth() {
        if (!root.bluetoothOn) {
            setBtProc.command = ["rfkill", "unblock", "bluetooth"];
            setBtProc.running = true;
            root.bluetoothOn = true;
        }
        root.isScanningBt = true;
        btScanProc.running = true;
    }

    function connectBt(mac) {
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["bluetoothctl", "connect", mac];
        p.running = true;
        let timer = Qt.createQmlObject('import QtQuick; Timer { interval: 2000; repeat: false }', root);
        timer.triggered.connect(() => { root.scanBluetooth(); });
        timer.start();
    }

    function disconnectBt(mac) {
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["bluetoothctl", "disconnect", mac];
        p.running = true;
        let timer = Qt.createQmlObject('import QtQuick; Timer { interval: 1500; repeat: false }', root);
        timer.triggered.connect(() => { root.scanBluetooth(); });
        timer.start();
    }

    function toggleDnd() {
        root.dndActive = !root.dndActive;
        let swayncProc = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        swayncProc.command = ["swaync-client", "--toggle-dnd"];
        swayncProc.running = true;
        let t = Qt.createQmlObject('import QtQuick; Timer { interval: 600; repeat: false }', root);
        t.triggered.connect(() => { dndGetProc.running = true; });
        t.start();
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
}
