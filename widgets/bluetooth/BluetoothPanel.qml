// BluetoothPanel.qml

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.config
import qs.components
import qs.services

// Bluetooth settings for the sidebar: the radio switch, and the devices
// around to pair and connect.
ColumnLayout {
    id: root

    // Whether the panel is actually on screen. Discovery only runs while it is.
    property bool active: false

    // The device whose drawer is open, if any. Kept here rather than in the
    // cards so it survives the list reordering (a device that connects jumps
    // to the top).
    property var expanded: null

    onActiveChanged: if (!root.active) root.expanded = null

    Binding {
        target: Bluetooth
        property: "scanning"
        value: root.active
    }

    spacing: Theme.paddings

    // Header: title + what's connected, radio switch
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.spacing

        spacing: Theme.paddings

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: "Bluetooth"
                color: Theme.colors.fg

                font.family: Theme.font.family
                font.pixelSize: Theme.font.size
                font.weight: Font.Medium
            }

            Text {
                Layout.fillWidth: true

                text: {
                    if (!Bluetooth.available) return "Unavailable"
                    if (!Bluetooth.powered) return "Off"

                    const connected = Bluetooth.connectedDevices
                    if (connected.length === 0) return "No devices connected"
                    if (connected.length === 1) return "Connected to " + connected[0].name
                    return connected.length + " devices connected"
                }
                elide: Text.ElideRight
                color: Theme.colors.muted

                font.family: Theme.font.family
                font.pixelSize: Theme.font.small
            }
        }

        IconButton {
            enabled: Bluetooth.available
            baseColor: Theme.colors.surfaceHigh

            icon: Bluetooth.powered ? "bluetooth" : "bluetooth_disabled"
            checked: Bluetooth.powered

            onClicked: Bluetooth.toggle()
        }
    }

    // Empty states
    Item {
        visible: !Bluetooth.powered || Bluetooth.devices.length === 0

        Layout.fillWidth: true
        Layout.fillHeight: true

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacing

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: !Bluetooth.available || !Bluetooth.powered ? "bluetooth_disabled" : "bluetooth_searching"
                color: Theme.colors.muted

                font.family: Theme.font.icons
                font.pixelSize: Theme.font.large * 2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: !Bluetooth.available ? "Bluetooth is unavailable"
                    : !Bluetooth.powered ? "Bluetooth is off"
                    : "Searching for devices…"
                color: Theme.colors.muted

                font.family: Theme.font.family
                font.pixelSize: Theme.font.size
            }
        }
    }

    ListView {
        visible: Bluetooth.powered && Bluetooth.devices.length > 0

        Layout.fillWidth: true
        Layout.fillHeight: true

        clip: true
        spacing: Theme.pVertical

        model: ScriptModel {
            values: Bluetooth.devices
        }

        delegate: BluetoothDeviceEntry {
            required property var modelData

            width: ListView.view.width

            device: modelData
            open: root.expanded === modelData

            onToggleRequested: root.expanded = root.expanded === modelData ? null : modelData
        }
    }
}
