// Session.qml

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Power and session actions, for the power menu. logind allows all of the
// systemctl ones without a password here (checked with --dry-run).
Singleton {
    id: root

    // First screen locker found on the system, "" if there's none; the lock
    // entry only shows when there's something to run.
    property string locker: ""

    function lock() {
        if (root.locker !== "") Quickshell.execDetached([root.locker])
    }

    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"])
    }

    // Same as the Super+M bind in hyprland.lua. The config is Lua, so the
    // dispatcher takes a Lua expression instead of the classic `exit`.
    function logout() {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"])
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"])
    }

    function poweroff() {
        Quickshell.execDetached(["systemctl", "poweroff"])
    }

    Process {
        command: ["sh", "-c", "for l in hyprlock swaylock gtklock; do command -v $l && break; done"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.locker = this.text.trim()
        }
    }
}
