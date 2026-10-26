// Brightness.qml

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

import qs.config

Singleton {
    id: root

    readonly property string device: Settings.brightness.device
    readonly property string path: "/sys/class/backlight/" + device

    // Current and maximum value in the device's own units (this panel goes
    // 0 - 400, not 0 - 100), so the ratio is the only meaningful level.
    property int raw: 0
    property int max: 0

    readonly property bool ready: max > 0
    readonly property real level: ready ? raw / max : 0 // 0.0 - 1.0
    readonly property real percent: level * 100

    // Latest value requested while a write was still in flight, in device
    // units; -1 when nothing is queued.
    property int queued: -1

    // Date.now() of the last write the shell made itself (scroll, dim
    // toggle). udev reports those and the media keys' the same way; the OSD
    // uses this to only answer the keys.
    property double localChangeAt: 0

    // sysfs is root-owned and this system has no udev rule granting the video
    // group write access, so brightness can be read directly but only *set*
    // through brightnessctl, which routes the write through logind.
    function setLevel(value) {
        if (!root.ready) return

        const target = Math.round(Math.max(0, Math.min(1, value)) * root.max)
        const clamped = Math.max(Settings.brightness.minimum, Math.min(root.max, target))

        // brightnessctl takes a few milliseconds to come back, which a fast
        // scroll outruns. Keep the last request instead of dropping it or
        // stacking processes.
        if (writeProcess.running) {
            root.queued = clamped
            return
        }

        root.write(clamped)
    }

    // Level to go back to when the dim toggle is switched off; -1 when not
    // dimmed. Dropped as soon as brightness moves off the floor by any other
    // means (scroll, media keys), so the toggle never claims a state the panel
    // isn't in.
    property real restoreLevel: -1
    readonly property bool dimmed: restoreLevel >= 0

    function toggleDim() {
        if (!root.ready) return

        if (root.dimmed) {
            const target = root.restoreLevel
            root.restoreLevel = -1
            root.setLevel(target)
        } else {
            root.restoreLevel = root.level
            root.setLevel(0) // Clamped to Settings.brightness.minimum
        }
    }

    onRawChanged: {
        if (root.dimmed && root.raw > Settings.brightness.minimum) root.restoreLevel = -1
    }

    function increase() {
        root.setLevel(root.level + Settings.brightness.step / 100)
    }

    function decrease() {
        root.setLevel(root.level - Settings.brightness.step / 100)
    }

    function write(value) {
        root.queued = -1
        root.localChangeAt = Date.now()

        writeProcess.command = [
            "brightnessctl", "--device", root.device, "set", value + ""
        ]
        writeProcess.running = true
    }

    Process {
        id: writeProcess

        onExited: {
            if (root.queued >= 0) root.write(root.queued)
        }
    }

    // Read once: a panel's maximum doesn't change at runtime.
    //
    // Both reads land about 8ms after this singleton is first touched (QML
    // instantiates singletons lazily), so `ready` is false and `level` is 0 for
    // the first frame of whatever binds to them. Reading only inside `onLoaded`
    // keeps that window to one frame without blocking the UI thread on each
    // later reload.
    FileView {
        id: maxFile

        path: root.path + "/max_brightness"
        onLoaded: root.max = parseInt(maxFile.text().trim())
    }

    FileView {
        id: rawFile

        path: root.path + "/brightness"

        // reload() resolves asynchronously — the new contents are only
        // readable here, not on the line after the call.
        onLoaded: root.raw = parseInt(rawFile.text().trim())
    }

    // The kernel emits a udev `change` event on the backlight device every time
    // brightness moves, including when something outside the shell moves it
    // (the Hyprland media keys run brightnessctl directly). Watching that keeps
    // the value live with no polling — FileView's `watchChanges` can't do it,
    // because inotify doesn't fire on sysfs attributes.
    Process {
        id: monitor

        command: ["udevadm", "monitor", "--udev", "--subsystem-match=backlight"]
        running: true

        stdout: SplitParser {
            onRead: (line) => {
                if (line.includes("change") && line.includes(root.device)) {
                    rawFile.reload()
                }
            }
        }
    }
}
