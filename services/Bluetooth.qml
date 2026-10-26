// Bluetooth.qml

pragma Singleton

import Quickshell
import QtQuick

// Qualified: this file's own name would otherwise shadow Quickshell's
// Bluetooth singleton.
import Quickshell.Bluetooth as Bt

Singleton {
    id: root

    // null while BlueZ isn't running, and for about a second after this is
    // first touched. Quickshell only looks for BlueZ once, when the shell
    // starts: if bluetoothd comes up later, the adapter doesn't show until
    // qs is restarted (a config reload isn't enough).
    readonly property var adapter: Bt.Bluetooth.defaultAdapter

    readonly property bool available: root.adapter !== null
    readonly property bool powered: root.available && root.adapter.enabled

    // Set by whatever shows the device list, while it's on screen: discovery
    // keeps the radio busy, so it only runs when someone is looking.
    property bool scanning: false

    Binding {
        when: root.available
        target: root.adapter
        property: "discovering"
        value: root.scanning && root.powered
    }

    // Devices worth listing, best first: connected, then paired, then by name.
    // Discovery turns up lots of low-energy beacons with no name (just the
    // address); those only show once paired.
    readonly property var devices: {
        if (!root.available) return []

        const rank = d => d.connected ? 0 : d.paired ? 1 : 2

        return root.adapter.devices.values
            .filter(d => d.paired || d.deviceName.length > 0)
            .sort((a, b) => rank(a) - rank(b) || a.name.localeCompare(b.name))
    }

    readonly property var connectedDevices: root.devices.filter(d => d.connected)

    // BlueZ's freedesktop icon names, as Material Symbols.
    function deviceIcon(device) {
        const icon = device?.icon ?? ""

        if (icon.startsWith("audio-headset") || icon.startsWith("audio-headphones")) return "headphones"
        if (icon.startsWith("audio")) return "speaker"
        if (icon === "input-mouse") return "mouse"
        if (icon === "input-keyboard") return "keyboard"
        if (icon === "input-gaming") return "sports_esports"
        if (icon === "input-tablet") return "stylus"
        if (icon.startsWith("phone")) return "smartphone"
        if (icon === "computer") return "computer"
        if (icon.startsWith("video")) return "tv"
        if (icon.startsWith("camera")) return "photo_camera"
        if (icon === "printer") return "print"
        return "bluetooth"
    }

    // New devices get paired first, and trusted so they reconnect on their
    // own later. There's no pairing agent here, so only devices that pair
    // without a PIN or a confirmation code (most headphones, speakers and
    // mice) can be paired from the shell.
    function pairAndConnect(device) {
        if (!device) return

        device.trusted = true
        if (device.paired) device.connect()
        else device.pair()
    }

    function toggle() {
        if (!root.available) return
        root.adapter.enabled = !root.adapter.enabled
    }
}
