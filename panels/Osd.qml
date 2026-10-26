// Osd.qml

import Quickshell
import Quickshell.Wayland
import QtQuick

import qs.config
import qs.services
import qs.components

// On-screen display for the hardware keys: volume and mute, microphone mute,
// brightness, and the media keys. Hyprland runs wpctl/brightnessctl for the
// first ones directly, so without this nothing on screen would answer a key
// press; the media keys come through Media's IPC instead.
//
// The same card as the tooltips, centered below the bar, level with the
// toasts and the sidebar; it stays Settings.osd.timeout after the last
// change. Changes made from the shell's own controls (scrolling the bar's
// volume, the sidebar's toggles) don't show it: those show the value
// themselves.
Scope {
    id: root

    property string kind: "" // "volume", "microphone", "brightness" or "media"
    property bool shown: false

    // Pipewire and udev report a change the shell made itself within a few
    // milliseconds of the write, so a change this soon after one is taken
    // for its echo rather than a key press.
    readonly property int echo: 500 // ms

    function show(kind) {
        root.kind = kind
        root.shown = true
        hide.restart()
    }

    Timer {
        id: hide

        interval: Settings.osd.timeout
        onTriggered: root.shown = false
    }

    // Last state seen of each device. Only a value that moved on the same,
    // already known device counts: a device showing up (the shell starting,
    // Pipewire coming up late) or being switched (headphones plugged in)
    // changes the values as well, and isn't a key press.
    property var lastSink: null
    property real lastVolume: 0
    property bool lastMuted: false

    property var lastSource: null
    property bool lastMicMuted: false

    property int lastRaw: -1

    function checkVolume() {
        const sink = Audio.ready ? Audio.sink : null
        const moved = sink !== null && sink === root.lastSink
            && (Audio.volume !== root.lastVolume || Audio.muted !== root.lastMuted)

        root.lastSink = sink
        root.lastVolume = Audio.volume
        root.lastMuted = Audio.muted

        if (moved && Date.now() - Audio.localChangeAt > root.echo) root.show("volume")
    }

    // Nothing in the shell mutes the microphone, so there's no echo to skip.
    function checkMicrophone() {
        const source = Audio.micReady ? Audio.source : null
        const moved = source !== null && source === root.lastSource
            && Audio.micMuted !== root.lastMicMuted

        root.lastSource = source
        root.lastMicMuted = Audio.micMuted

        if (moved) root.show("microphone")
    }

    function checkBrightness() {
        const raw = Brightness.ready ? Brightness.raw : -1
        const moved = raw >= 0 && root.lastRaw >= 0 && raw !== root.lastRaw

        root.lastRaw = raw

        if (moved && Date.now() - Brightness.localChangeAt > root.echo) root.show("brightness")
    }

    // Deferred: several of these fire together when a device appears or
    // switches, and checking once they've all landed sees a consistent
    // state. Qt.callLater folds repeated calls in one go into one.
    Connections {
        target: Audio

        function onSinkChanged() { Qt.callLater(root.checkVolume) }
        function onReadyChanged() { Qt.callLater(root.checkVolume) }
        function onVolumeChanged() { Qt.callLater(root.checkVolume) }
        function onMutedChanged() { Qt.callLater(root.checkVolume) }

        function onSourceChanged() { Qt.callLater(root.checkMicrophone) }
        function onMicReadyChanged() { Qt.callLater(root.checkMicrophone) }
        function onMicMutedChanged() { Qt.callLater(root.checkMicrophone) }
    }

    // Only the keys: the bar's buttons don't go through Media's IPC.
    Connections {
        target: Media

        function onKeyPressed() { if (Media.available) root.show("media") }
    }

    Connections {
        target: Brightness

        function onReadyChanged() { Qt.callLater(root.checkBrightness) }
        function onRawChanged() { Qt.callLater(root.checkBrightness) }
    }

    Component.onCompleted: {
        root.checkVolume()
        root.checkMicrophone()
        root.checkBrightness()
    }

    // Live while on screen: holding a key down updates the card in place.
    readonly property var content: {
        switch (root.kind) {
        case "volume":
            return {
                icon: Audio.muted ? "volume_off" : Audio.volume < 0.5 ? "volume_down" : "volume_up",
                title: "Volume",
                meta: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%",
                body: Audio.device,
                progress: Audio.volume,
                progressColor: Audio.muted ? Theme.colors.muted : Theme.colors.accent
            }
        case "microphone":
            return {
                icon: Audio.micMuted ? "mic_off" : "mic",
                title: "Microphone",
                meta: Audio.micMuted ? "Muted" : "On",
                body: Audio.micDevice
            }
        case "brightness":
            return {
                icon: "brightness_6",
                title: "Brightness",
                meta: Math.round(Brightness.percent) + "%",
                progress: Brightness.level
            }
        // Live too: after next/previous the player sends the new track a
        // moment later, and the card catches up in place.
        case "media":
            return {
                icon: Media.isPlaying ? "play_arrow" : "pause",
                picture: Media.artUrl,
                title: Media.title,
                meta: Media.isPlaying ? "Playing" : "Paused",
                body: Media.artist || Media.app,
                progress: Media.length > 0 ? Media.position / Media.length : -1
            }
        }

        return {}
    }

    PanelWindow {
        // Stays mapped until the fade-out is over.
        visible: root.shown || card.opacity > 0
        color: "transparent"

        // Overlay, above fullscreen windows too: a key pressed during a
        // video still needs an answer.
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:osd"
        exclusionMode: ExclusionMode.Ignore

        // Never takes input: the pointer and clicks pass straight through.
        mask: Region {}

        // Only the top edge, so the compositor centers it horizontally; the
        // same distance from the top as the toasts and the sidebar.
        anchors {
            top: true
        }

        margins {
            top: Theme.margins + Settings.bar.height + Theme.margins
        }

        // Fixed width, so holding a key doesn't make it jitter as the
        // numbers change.
        implicitWidth: Settings.osd.width
        implicitHeight: Math.ceil(card.naturalHeight)

        InfoCard {
            id: card

            anchors.fill: parent

            shown: root.shown

            icon: root.content.icon ?? ""
            picture: root.content.picture ?? ""
            title: root.content.title ?? ""
            meta: root.content.meta ?? ""
            body: root.content.body ?? ""
            progress: root.content.progress ?? -1
            progressColor: root.content.progressColor ?? Theme.colors.accent
        }
    }
}
