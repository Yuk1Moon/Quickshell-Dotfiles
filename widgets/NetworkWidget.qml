// NetworkWidget.qml

import QtQuick
import QtQuick.Layouts

import qs.config
import qs.services
import qs.components

PillContainer {
    id: pill

    RowLayout {
        id: root

        anchors.verticalCenter: parent.verticalCenter
        
        spacing: Theme.spacing

        // Status Color
        readonly property color statusColor: {
            return Network.connected ? Theme.colors.fg : Theme.colors.error
        }

        // Status Icon
        readonly property string iconName: {
            if (Network.wifi) return "wifi"
            if (Network.ethernet) return "hive"
            return "wifi_off"
        }

        // Icon
        Text {
            text: root.iconName
            color: root.statusColor

            font.family: Theme.font.icons
            font.pixelSize: Theme.font.medium
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: Network.ip
            color: root.statusColor

            font.family: Theme.font.family
            font.pixelSize: Theme.font.size
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Tooltip {
        target: pill

        // Signal of the network in use, from the same list the sidebar shows.
        readonly property var network: Network.wifi
            ? Network.wifiNetworks.find(n => n.connected) ?? null
            : null

        icon: root.iconName
        alert: !Network.connected

        title: Network.connected ? Network.name : "Offline"
        meta: network ? Math.round(network.signalStrength * 100) + "%" : ""
        body: {
            if (!Network.connected) return Network.wifiEnabled ? "Not connected" : "Wi-Fi is off"

            const kind = Network.wifi ? "Wi-Fi" : "Ethernet"
            return Network.ip !== "" ? kind + " · " + Network.ip : kind
        }
    }
}