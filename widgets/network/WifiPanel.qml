// WifiPanel.qml

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.config
import qs.components
import qs.services

// Wi-Fi settings for the sidebar: the radio switch, and the networks in
// range to connect to.
ColumnLayout {
    id: root

    // Whether the panel is actually on screen. Scanning only runs while it is.
    property bool active: false

    // The network whose drawer is open, if any. Kept here rather than in the
    // cards so it survives the list reordering (the one being connected to
    // jumps to the top).
    property var expanded: null

    // A password field is showing, so the window needs the keyboard.
    readonly property bool typing: root.expanded !== null
        && !root.expanded.connected
        && Network.needsPassword(root.expanded)
        && Network.supportsPassword(root.expanded)

    onActiveChanged: if (!root.active) root.expanded = null

    Binding {
        target: Network
        property: "scanning"
        value: root.active
    }

    spacing: Theme.paddings

    // Header: title + current connection, radio switch
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.spacing

        spacing: Theme.paddings

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: "Wi-Fi"
                color: Theme.colors.fg

                font.family: Theme.font.family
                font.pixelSize: Theme.font.size
                font.weight: Font.Medium
            }

            Text {
                Layout.fillWidth: true

                text: !Network.wifiEnabled ? "Off"
                    : Network.wifi ? "Connected to " + Network.name
                    : "Not connected"
                elide: Text.ElideRight
                color: Theme.colors.muted

                font.family: Theme.font.family
                font.pixelSize: Theme.font.small
            }
        }

        IconButton {
            baseColor: Theme.colors.surfaceHigh

            icon: Network.wifiEnabled ? "wifi" : "wifi_off"
            checked: Network.wifiEnabled

            onClicked: Network.toggleWifi()
        }
    }

    // Empty states
    Item {
        visible: !Network.wifiEnabled || Network.wifiNetworks.length === 0

        Layout.fillWidth: true
        Layout.fillHeight: true

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacing

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: Network.wifiEnabled ? "wifi_find" : "wifi_off"
                color: Theme.colors.muted

                font.family: Theme.font.icons
                font.pixelSize: Theme.font.large * 2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: Network.wifiEnabled ? "Searching for networks…" : "Wi-Fi is off"
                color: Theme.colors.muted

                font.family: Theme.font.family
                font.pixelSize: Theme.font.size
            }
        }
    }

    ListView {
        visible: Network.wifiEnabled && Network.wifiNetworks.length > 0

        Layout.fillWidth: true
        Layout.fillHeight: true

        clip: true
        spacing: Theme.pVertical

        model: ScriptModel {
            values: Network.wifiNetworks
        }

        delegate: WifiNetworkEntry {
            required property var modelData

            width: ListView.view.width

            network: modelData
            open: root.expanded === modelData

            onToggleRequested: root.expanded = root.expanded === modelData ? null : modelData
        }
    }
}
