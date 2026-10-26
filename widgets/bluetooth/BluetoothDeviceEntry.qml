// BluetoothDeviceEntry.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth as Bt

import qs.config
import qs.components
import qs.services

// One device in the Bluetooth list, as a card like the Wi-Fi ones. Clicking a
// paired device connects it, and a new one gets paired and then connected;
// the connected one opens a drawer with disconnect / forget instead.
Control {
    id: root

    required property var device

    // Owned by the list, so it survives the list reordering itself.
    property bool open: false

    signal toggleRequested()

    // The device object is destroyed as soon as BlueZ drops it, a moment
    // before the list removes this card. Everything reads it through these,
    // so the card doesn't throw on its way out.
    readonly property bool isConnected: root.device?.connected ?? false
    readonly property bool isPaired: root.device?.paired ?? false
    readonly property bool isPairing: root.device?.pairing ?? false
    readonly property string deviceName: root.device?.name ?? ""
    readonly property bool hasBattery: root.device?.batteryAvailable ?? false
    readonly property real battery: root.device?.battery ?? 0

    readonly property bool connecting: root.device?.state === Bt.BluetoothDeviceState.Connecting
        || root.device?.state === Bt.BluetoothDeviceState.Disconnecting

    // BlueZ reports no failure reasons, only the state falling back. An
    // attempt that ends without the device connected counts as failed.
    property bool attempting: false
    property string error: ""

    readonly property string status: {
        if (root.error !== "") return root.error
        if (root.isPairing) return "Pairing…"
        if (root.connecting) return root.isConnected ? "Disconnecting…" : "Connecting…"

        const battery = root.hasBattery ? " · " + Math.round(root.battery * 100) + "%" : ""
        if (root.isConnected) return "Connected" + battery
        if (root.isPaired) return "Paired" + battery
        return "Not paired"
    }

    function activate() {
        if (!root.device) return

        if (root.isConnected) {
            root.toggleRequested()
            return
        }

        if (root.isPairing) {
            root.device.cancelPair()
            return
        }

        root.error = ""
        root.attempting = true
        Bluetooth.pairAndConnect(root.device)
    }

    Connections {
        target: root.device

        // Paired: go on and connect.
        function onPairedChanged() {
            if (root.isPaired && root.attempting) root.device.connect()
        }

        function onPairingChanged() {
            if (!root.isPairing && !root.isPaired && root.attempting) {
                root.attempting = false
                root.error = "Couldn't pair"
            }
        }

        function onStateChanged() {
            if (!root.attempting || root.isPairing) return

            if (root.isConnected) {
                root.attempting = false
            } else if (root.device.state === Bt.BluetoothDeviceState.Disconnected && root.isPaired) {
                root.attempting = false
                root.error = "Couldn't connect"
            }
        }
    }

    hoverEnabled: true
    padding: Theme.paddings

    background: Rectangle {
        radius: Theme.radius
        color: root.isConnected ? Theme.colors.container : Theme.colors.surface

        Rectangle {
            anchors.fill: parent
            radius: parent.radius

            color: Theme.colors.hover
            opacity: headerCursor.containsMouse ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: Theme.paddings

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.paddings

            // Device type badge
            Rectangle {
                implicitWidth: 36
                implicitHeight: 36
                radius: width / 2

                color: root.isConnected ? Theme.colors.accent : Theme.colors.hover

                Text {
                    anchors.centerIn: parent

                    text: Bluetooth.deviceIcon(root.device)
                    color: root.isConnected ? Theme.colors.onAccent : Theme.colors.fg

                    font.family: Theme.font.icons
                    font.pixelSize: Theme.font.large
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing / 2

                Text {
                    Layout.fillWidth: true

                    text: root.deviceName
                    elide: Text.ElideRight
                    color: Theme.colors.fg

                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.size
                    font.weight: Font.Medium
                }

                Text {
                    Layout.fillWidth: true

                    text: root.status
                    elide: Text.ElideRight
                    color: root.error !== "" ? Theme.colors.error : Theme.colors.muted

                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.small
                }
            }
        }

        // Drawer: connected device
        RowLayout {
            visible: root.open && root.isConnected

            Layout.fillWidth: true
            spacing: Theme.spacing

            PillButton {
                Layout.fillWidth: true

                text: "Disconnect"
                onClicked: root.device?.disconnect()
            }

            PillButton {
                Layout.fillWidth: true

                text: "Forget"
                onClicked: root.device?.forget()
            }
        }
    }

    // Header click target only: the drawer has its own controls.
    MouseArea {
        id: headerCursor

        x: 0
        y: 0
        z: 1
        width: root.width
        height: root.topPadding + 36 + root.bottomPadding

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.activate()
    }
}
