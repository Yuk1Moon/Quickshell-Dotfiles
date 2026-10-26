// WifiNetworkEntry.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Networking as Nm

import qs.config
import qs.components
import qs.services

// One network in the Wi-Fi list, as a card like the notification ones.
// Clicking a saved or open network connects straight away; the connected one
// and new secured ones open a drawer below instead (disconnect / forget, or
// the password field).
Control {
    id: root

    required property var network

    // Owned by the list, so it survives the list reordering itself.
    property bool open: false

    signal toggleRequested()

    // The network object is destroyed as soon as it drops out of range, a
    // moment before the list removes this card. Everything reads it through
    // these, so the card doesn't throw on its way out.
    readonly property bool isConnected: root.network?.connected ?? false
    readonly property bool isKnown: root.network?.known ?? false
    readonly property string networkName: root.network?.name ?? ""
    readonly property real signal: root.network?.signalStrength ?? 0
    readonly property int security: root.network?.security ?? Nm.WifiSecurityType.Unknown

    readonly property bool connecting: (root.network?.stateChanging ?? false)
        || root.network?.state === Nm.ConnectionState.Connecting

    readonly property bool secured: Network.isSecured(root.network)

    // Last failure, cleared on the next attempt.
    property string error: ""

    readonly property string status: {
        if (root.error !== "") return root.error
        if (root.connecting) return "Connecting…"
        if (root.isConnected) return "Connected"

        const security = Nm.WifiSecurityType.toString(root.security)
        return root.isKnown ? "Saved · " + security : security
    }

    readonly property string signalIcon: {
        const level = Math.round(root.signal * 4)
        if (level >= 4) return "signal_wifi_4_bar"
        if (level === 3) return "network_wifi_3_bar"
        if (level === 2) return "network_wifi_2_bar"
        if (level === 1) return "network_wifi_1_bar"
        return "signal_wifi_0_bar"
    }

    function activate() {
        if (!root.network) return

        if (root.isConnected || Network.needsPassword(root.network)) {
            root.toggleRequested()
            return
        }

        root.error = ""
        root.network.connect()
    }

    function submit() {
        if (!root.network || password.text.length === 0) return

        root.error = ""
        root.network.connectWithPsk(password.text)
    }

    Connections {
        target: root.network

        function onConnectionFailed(reason) {
            root.error = Network.failReason(reason)
        }

        // Done: fold the drawer and drop the typed password.
        function onConnectedChanged() {
            if (root.isConnected && root.open) root.toggleRequested()
        }
    }

    onOpenChanged: {
        password.text = ""
        password.echoMode = TextInput.Password

        if (root.open && passwordRow.visible) password.forceActiveFocus()
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

            // Signal badge
            Rectangle {
                implicitWidth: 36
                implicitHeight: 36
                radius: width / 2

                color: root.isConnected ? Theme.colors.accent : Theme.colors.hover

                Text {
                    anchors.centerIn: parent

                    text: root.signalIcon
                    color: root.isConnected ? Theme.colors.onAccent : Theme.colors.fg

                    font.family: Theme.font.icons
                    font.pixelSize: Theme.font.large
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing / 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing

                    Text {
                        Layout.fillWidth: true

                        text: root.networkName
                        elide: Text.ElideRight
                        color: Theme.colors.fg

                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.size
                        font.weight: Font.Medium
                    }

                    Text {
                        visible: root.secured

                        text: "lock"
                        color: Theme.colors.muted

                        font.family: Theme.font.icons
                        font.pixelSize: Theme.font.size
                    }
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

        // Drawer: connected network
        RowLayout {
            visible: root.open && root.isConnected

            Layout.fillWidth: true
            spacing: Theme.spacing

            PillButton {
                Layout.fillWidth: true

                text: "Disconnect"
                onClicked: root.network?.disconnect()
            }

            PillButton {
                Layout.fillWidth: true

                text: "Forget"
                onClicked: root.network?.forget()
            }
        }

        // Drawer: new secured network
        RowLayout {
            id: passwordRow

            visible: root.open && !root.isConnected && Network.supportsPassword(root.network)

            Layout.fillWidth: true
            spacing: Theme.spacing

            TextField {
                id: password

                Layout.fillWidth: true
                implicitHeight: 32

                leftPadding: Theme.paddings
                rightPadding: reveal.width + Theme.spacing

                echoMode: TextInput.Password
                placeholderText: "Password"
                placeholderTextColor: Theme.colors.muted

                color: Theme.colors.fg
                selectionColor: Theme.colors.accent

                font.family: Theme.font.family
                font.pixelSize: Theme.font.size

                background: Rectangle {
                    color: Theme.colors.surfaceHigh
                    radius: height / 2

                    border.width: password.activeFocus ? 2 : 1
                    border.color: password.activeFocus ? Theme.colors.selected : Theme.colors.muted

                    Behavior on border.color {
                        ColorAnimation { duration: 120 }
                    }
                }

                onAccepted: root.submit()
                Keys.onEscapePressed: root.toggleRequested()

                IconButton {
                    id: reveal

                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacing
                    anchors.verticalCenter: parent.verticalCenter

                    size: 24
                    icon: password.echoMode === TextInput.Password ? "visibility" : "visibility_off"

                    onClicked: password.echoMode = password.echoMode === TextInput.Password
                        ? TextInput.Normal : TextInput.Password
                }
            }

            PillButton {
                text: root.connecting ? "…" : "Connect"
                enabled: password.text.length > 0 && !root.connecting

                onClicked: root.submit()
            }
        }

        // Drawer: enterprise (EAP) network, which a password field can't set up
        Text {
            visible: root.open && !root.isConnected && root.network !== null && !Network.supportsPassword(root.network)

            Layout.fillWidth: true

            text: "This network needs an enterprise login. Set it up with nm-connection-editor."
            wrapMode: Text.Wrap
            color: Theme.colors.muted

            font.family: Theme.font.family
            font.pixelSize: Theme.font.small
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
