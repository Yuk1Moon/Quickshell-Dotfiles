// QuickToggles.qml

import QtQuick
import QtQuick.Layouts

import qs.config
import qs.services
import qs.components

// A rounded strip as wide as its parent gives it, with the buttons spread
// edge to edge. Same padding on every side, so the end circles sit as far
// from the strip's ends as from its top and bottom.
CardContainer {
    id: root

    padding: Theme.pVertical

    implicitHeight: row.implicitHeight + root.topPadding + root.bottomPadding
    radius: height / 2

    RowLayout {
        id: row

        anchors.fill: parent

        // Whatever width the buttons don't use becomes the gap between them.
        spacing: {
            let used = 0
            let count = 0

            for (const child of row.children) {
                if (!child.visible) continue
                used += child.implicitWidth
                count++
            }

            return count > 1 ? Math.max(0, (row.width - used) / (count - 1)) : 0
        }

        // Tooltips hang below the whole strip rather than each button, so
        // they all line up, the way the bar's hang below the bar.
        QuickToggle {
            id: wifi

            icon: Network.wifiEnabled ? "wifi" : "wifi_off"
            checked: Network.wifiEnabled

            onClicked: Network.toggleWifi()

            Tooltip {
                target: wifi
                below: root

                icon: wifi.icon
                title: "Wi-Fi"
                meta: Network.wifiEnabled ? "On" : "Off"
                body: !Network.wifiEnabled ? ""
                    : Network.wifi ? "Connected to " + Network.name
                    : "Not connected"
            }
        }

        QuickToggle {
            id: bluetooth

            enabled: Bluetooth.available

            icon: Bluetooth.powered ? "bluetooth" : "bluetooth_disabled"
            checked: Bluetooth.powered

            onClicked: Bluetooth.toggle()

            Tooltip {
                target: bluetooth
                below: root

                readonly property var connected: Bluetooth.connectedDevices

                icon: bluetooth.icon
                title: "Bluetooth"
                meta: Bluetooth.powered ? "On" : "Off"
                body: !Bluetooth.powered ? ""
                    : connected.length === 0 ? "No devices connected"
                    : connected.length === 1 ? "Connected to " + connected[0].name
                    : connected.length + " devices connected"
            }
        }

        // Click mutes, scroll adjusts — same as VolumeWidget in the bar,
        // including the error color while muted.
        QuickToggle {
            id: volume

            icon: Audio.muted ? "volume_off" : "volume_up"
            iconColor: Audio.muted ? Theme.colors.error : Theme.colors.fg
            level: Audio.volume
            ringColor: Audio.muted ? Theme.colors.muted : Theme.colors.accent

            onClicked: Audio.toggleMute()
            onScrolled: (direction) => Audio.setVolume(Audio.volume + direction * Settings.audio.step / 100)

            Tooltip {
                target: volume
                below: root

                icon: volume.icon
                title: "Volume"
                meta: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
                body: Audio.device
                progress: Audio.volume
                progressColor: volume.ringColor
            }
        }

        // Click drops to the floor and back, scroll adjusts.
        QuickToggle {
            id: brightness

            icon: Brightness.dimmed ? "brightness_low" : "brightness_high"
            level: Brightness.level

            onClicked: Brightness.toggleDim()
            onScrolled: (direction) => direction > 0 ? Brightness.increase() : Brightness.decrease()

            Tooltip {
                target: brightness
                below: root

                icon: brightness.icon
                title: "Brightness"
                meta: Math.round(Brightness.percent) + "%"
                body: Brightness.dimmed ? "Dimmed" : ""
                progress: Brightness.level
            }
        }

        // Do not disturb: toasts stop, notifications still land in the history.
        QuickToggle {
            id: dnd

            icon: Notifications.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
            checked: Notifications.dnd

            onClicked: Notifications.dnd = !Notifications.dnd

            Tooltip {
                target: dnd
                below: root

                icon: dnd.icon
                title: "Do not disturb"
                meta: Notifications.dnd ? "On" : "Off"
                body: Notifications.dnd ? "Only critical notifications pop up" : ""
            }
        }

        // Room for two more toggles, as in the reference layout.
        EmptySlot {}
        EmptySlot {}
    }
}
