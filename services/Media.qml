// Media.qml

pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

// What's playing, from the MPRIS players (browsers, Spotify, mpv...), and
// the controls for it. One player at a time: the one playing, or else the
// one that played last, so pausing doesn't swap it for another one.
Singleton {
    id: root

    readonly property var players: Mpris.players.values

    readonly property var playing: root.players.find(player => player.isPlaying) ?? null

    // The last player that was playing. Kept while it's open, even paused.
    property var lastPlayed: null
    onPlayingChanged: if (root.playing) root.lastPlayed = root.playing

    readonly property var player: root.playing
        ?? root.players.find(player => player === root.lastPlayed)
        ?? root.players[0]
        ?? null

    readonly property bool available: root.player !== null

    readonly property bool isPlaying: root.player?.isPlaying ?? false
    readonly property string title: root.player?.trackTitle || root.player?.identity || ""
    readonly property string artist: root.player?.trackArtist ?? ""
    readonly property string album: root.player?.trackAlbum ?? ""
    readonly property string artUrl: root.player?.trackArtUrl ?? ""

    // The app playing it: "Brave", "Spotify".
    readonly property string app: root.player?.identity ?? ""

    readonly property bool canPlayPause: root.player?.canTogglePlaying ?? false
    readonly property bool canNext: root.player?.canGoNext ?? false
    readonly property bool canPrevious: root.player?.canGoPrevious ?? false

    // Seconds. Players don't announce the position as it moves, only when it
    // jumps, so it's asked again every second while something plays.
    readonly property real position: root.player?.positionSupported ? root.player.position : 0
    readonly property real length: root.player?.lengthSupported ? root.player.length : 0

    Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying && (root.player?.positionSupported ?? false)
        onTriggered: root.player.positionChanged()
    }

    // "3:07", "1:02:45"
    function time(seconds) {
        const total = Math.max(0, Math.floor(seconds))
        const h = Math.floor(total / 3600)
        const m = Math.floor(total % 3600 / 60)
        const s = String(total % 60).padStart(2, "0")

        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + s : m + ":" + s
    }

    function playPause() {
        if (root.canPlayPause) root.player.togglePlaying()
    }

    function next() {
        if (root.canNext) root.player.next()
    }

    function previous() {
        if (root.canPrevious) root.player.previous()
    }

    // A media key was pressed (the IPC calls below); the OSD answers it.
    // The bar's own buttons don't go through here: they show the change
    // themselves.
    signal keyPressed()

    // `qs ipc call media playPause` — bound to the media keys in Hyprland,
    // in place of playerctl.
    IpcHandler {
        target: "media"

        function playPause(): void {
            root.playPause()
            root.keyPressed()
        }

        function next(): void {
            root.next()
            root.keyPressed()
        }

        function previous(): void {
            root.previous()
            root.keyPressed()
        }
    }
}
