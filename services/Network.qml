pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Networking as Nm
import QtQuick

import qs.config

Singleton {
    id: root

    // Variables
    property bool connected: false
    property bool wifi: false
    property bool ethernet: false
    property string name: "offline"

    // IPv4 address the system is using right now to reach the internet: the
    // source of the default route, so it follows whichever of wifi or
    // ethernet carries the traffic. "" while offline.
    property string ip: ""

    // Radio state, not connection state (`wifi` above is "connected over
    // wifi"). Read live from NetworkManager instead of the nmcli poll, so the
    // toggle flips the moment it's clicked.
    readonly property bool wifiEnabled: Nm.Networking.wifiEnabled

    function toggleWifi() {
        Nm.Networking.wifiEnabled = !Nm.Networking.wifiEnabled
    }

    // Wi-Fi settings

    readonly property var wifiDevice: Nm.Networking.devices.values
        .find(d => d.type === Nm.DeviceType.Wifi) ?? null

    // Set by whatever shows the network list, while it's on screen: scanning
    // keeps the radio busy, so it only runs when someone is looking.
    property bool scanning: false

    Binding {
        when: root.wifiDevice !== null
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.scanning && root.wifiEnabled
    }

    // Visible networks, best first: the connected one, then saved ones, then
    // by signal. Signal is bucketed in quarters so the list doesn't reshuffle
    // on every small fluctuation. Hidden networks (no name) are left out.
    readonly property var wifiNetworks: {
        if (!root.wifiDevice) return []

        const rank = n => n.connected ? 0 : n.known ? 1 : 2

        return root.wifiDevice.networks.values
            .filter(n => n.name.length > 0)
            .sort((a, b) => rank(a) - rank(b)
                || Math.round(b.signalStrength * 4) - Math.round(a.signalStrength * 4)
                || a.name.localeCompare(b.name))
    }

    // All of these take a network that may already be gone (null): network
    // objects are destroyed the moment they drop out of range.
    function isSecured(network) {
        return !!network
            && network.security !== Nm.WifiSecurityType.Open
            && network.security !== Nm.WifiSecurityType.Owe
    }

    // Saved and open networks connect directly; a new secured one needs its
    // password, which only makes sense for PSK-style networks — enterprise
    // (EAP) ones need more than a password field can give.
    function needsPassword(network) {
        return !!network && !network.known && root.isSecured(network)
    }

    function supportsPassword(network) {
        const s = network?.security
        return s === Nm.WifiSecurityType.WpaPsk
            || s === Nm.WifiSecurityType.Wpa2Psk
            || s === Nm.WifiSecurityType.Sae
            || s === Nm.WifiSecurityType.StaticWep
    }

    function failReason(reason) {
        switch (reason) {
        case Nm.ConnectionFailReason.NoSecrets:
        case Nm.ConnectionFailReason.WifiAuthTimeout:
            return "Wrong password"
        case Nm.ConnectionFailReason.WifiNetworkLost:
            return "Network out of range"
        default:
            return "Couldn't connect"
        }
    }

    function update(output) {
        connected = false
        wifi = false
        ethernet = false
        name = "offline"

        const connections = output.trim().split("\n")

        for (const connection of connections) {
            const separator = connection.indexOf(":")
            if (separator < 0)
                continue

            const type = connection.substring(0, separator)
            const connectionName = connection.substring(separator + 1)

            // Ethernet Priority
            if (type === "802-3-ethernet") {
                connected = true
                ethernet = true
                name = connectionName || "Ethernet"
                return
            }

            if (type === "802-11-wireless") {
                connected = true
                wifi = true
                ethernet = false
                name = connectionName
                return
            }
        }
    }

    function updateIp(output) {
        try {
            root.ip = JSON.parse(output)[0]?.prefsrc ?? ""
        } catch (e) {
            root.ip = "" // Offline: `ip` prints nothing to stdout
        }
    }

    Process {
        id: networkProcess

        command: [
            "nmcli", "--terse", "--escape", "no", "--fields", "TYPE,NAME",
            "connection", "show", "--active"
        ]

        running: true

        stdout: StdioCollector {
            onStreamFinished: root.update(this.text)
        }    
    }

    // A route lookup only: nothing is actually sent to 1.1.1.1.
    Process {
        id: ipProcess

        command: ["ip", "-j", "-4", "route", "get", "1.1.1.1"]

        running: true

        stdout: StdioCollector {
            onStreamFinished: root.updateIp(this.text)
        }
    }

    Timer {
        interval: Settings.network.pollInterval
        repeat: true
        running: true
        
        onTriggered: {
            if (!networkProcess.running) {
                networkProcess.running = true
            }

            if (!ipProcess.running) {
                ipProcess.running = true
            }
        }
    }

}