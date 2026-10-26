// Audio.qml

pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink

    readonly property bool ready: sink !== null && sink.ready
    readonly property bool muted: root.ready && sink.audio.muted
    readonly property real volume: root.ready ? sink.audio.volume : 0 // 0.0 - 1.0

    // Short name of the output ("Speaker", "HDMI 1"), falling back to the
    // full description, which here runs to "800 Series Chipset Family…".
    readonly property string device: sink ? (sink.nickname || sink.description) : ""

    // Microphone: only its mute state for now, which the mic-mute key flips.
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool micReady: source !== null && source.ready
    readonly property bool micMuted: root.micReady && source.audio.muted
    readonly property string micDevice: source ? (source.nickname || source.description) : ""

    // Date.now() of the last change made through setVolume()/toggleMute(),
    // i.e. from the shell's own controls. Pipewire reports those and the
    // media keys' the same way; the OSD uses this to only answer the keys.
    property double localChangeAt: 0

    // Keeps Pipewire subscribed to the default devices so their state updates live.
    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink, Pipewire.defaultAudioSource ]
    }

    function setVolume(value) {
        if (!root.ready) return
        root.localChangeAt = Date.now()
        sink.audio.volume = Math.max(0, Math.min(1, value))
    }

    function toggleMute() {
        if (!root.ready) return
        root.localChangeAt = Date.now()
        sink.audio.muted = !sink.audio.muted
    }
}
