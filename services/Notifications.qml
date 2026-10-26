// Notifications.qml
pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

import qs.config

Singleton {
    id: root

    // Notifications currently shown as toasts, oldest first.
    property var popups: []

    // History for the sidebar, newest first, capped at
    // Settings.notifications.maxHistory. Saved to disk, so it survives
    // reloads and restarts.
    //
    // Each entry is a plain snapshot of what was shown, plus `live`: the
    // Notification object while its sender still has it open, for its action
    // buttons and inline reply; null once it closes, and after a restart.
    // Snapshots rather than the objects themselves: Quickshell destroys a
    // notification the moment it's closed, and entries that were the object
    // turned to null a few seconds after arriving.
    property var history: []

    property bool centerOpen: false

    // Do not disturb: new notifications go to the history without a toast,
    // except critical ones — a low battery warning still needs seeing.
    property bool dnd: false

    // The notification whose inline reply field is open, one at a time.
    // Whichever window shows it takes the keyboard while this is set. Clears
    // itself if the notification closes.
    property QtObject replyingTo: null

    // False until the saved history has been read back: saving before that
    // would overwrite it with whatever arrived in the meantime.
    property bool restored: false

    function snapshot(notification) {
        return {
            key: Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
            id: notification.id, // The server's id, to find it again after a reload
            appName: notification.appName,
            appIcon: notification.appIcon,
            image: notification.image,
            summary: notification.summary,
            body: notification.body,
            urgency: notification.urgency,
            warning: root.warningKey(notification), // See warn()
            symbol: notification.hints?.["x-quickshell-symbol"] ?? "",
            time: new Date(), // The server keeps no timestamp
            live: notification
        }
    }

    // Warning toasts from the shell itself, e.g. a low battery. They go out
    // as real notifications to this same server, so they get what any other
    // does: the toast, the history, the save to disk and, critical ones, the
    // way through do not disturb. Two hints ride along: `key`, to find them
    // again, and a Material symbol for the badge, in the shell's style
    // instead of whatever the icon theme has.
    //
    // One warning per key: a new one replaces the one before it as it
    // arrives (see the server). Critical ones stay on screen until closed
    // instead of timing out.
    function warn(key, summary, body, symbol, critical) {
        const command = [
            "notify-send",
            "--app-name=Quickshell",
            "--urgency=" + (critical ? "critical" : "normal"),
            "--hint=string:x-quickshell-warning:" + key,
            "--hint=string:x-quickshell-symbol:" + symbol
        ]
        if (critical) command.push("--expire-time=0")

        Quickshell.execDetached([...command, "--", summary, body])
    }

    function warningKey(notification) {
        return notification.hints?.["x-quickshell-warning"] ?? ""
    }

    // Takes back the warnings under `key` once they no longer apply (the
    // charger went in): off the screen and out of the history.
    function clearWarning(key) {
        for (const entry of root.history.filter(e => e.warning === key)) {
            root.removeFromHistory(entry.key)
        }
    }

    // Sets the history, capped. Entries pushed off the end whose notification
    // is still open get it closed, or it would stay open with nothing left to
    // close it from.
    function setHistory(entries) {
        const max = Settings.notifications.maxHistory

        for (const entry of entries.slice(max)) {
            const live = entry.live
            if (live) Qt.callLater(() => live.expire())
        }

        root.history = entries.slice(0, max)
    }

    // Drops the entry's link once its notification closes; the snapshot
    // stays, without the actions and reply that went with it.
    //
    // Nothing here touches `tracked`: untracking from inside the
    // notification's own `closed` handler re-enters the close cycle and
    // spirals into thousands of `closed` signals for the same object.
    function watch(notification) {
        notification.closed.connect(() => {
            root.popups = root.popups.filter(n => n !== notification)

            if (root.history.some(entry => entry.live === notification)) {
                root.history = root.history.map(entry => entry.live === notification
                    ? Object.assign({}, entry, { live: null })
                    : entry)
            }
        })
    }

    // A toast's time is up. It leaves the screen, and the notification stays
    // open in the history — unless the sender marked it transient or set its
    // own timeout, i.e. it was never meant to outlive the toast.
    function hidePopup(notification) {
        root.popups = root.popups.filter(n => n !== notification)

        if (notification.transient || notification.expireTimeout > 0) notification.expire()
    }

    // A notification still open from before a live reload, which the server
    // hands over again (keepOnReload). It's already in the saved history, so
    // it goes back to its entry instead of arriving a second time. If the
    // history isn't read back yet, restore() links it when it is.
    function relink(notification) {
        if (!root.restored) return
        if (root.history.some(entry => entry.live === notification)) return // restore() got to it first

        const index = root.history.findIndex(entry => entry.live === null
            && entry.id === notification.id && entry.summary === notification.summary)

        if (index < 0) {
            root.adopt(notification)
            return
        }

        root.history = root.history.map((entry, i) => i === index
            ? Object.assign({}, entry, { live: notification })
            : entry)
    }

    // A notification carried over a reload with no saved entry to go back
    // to: it arrived just before the reload, before the save, or there was
    // no save to read. It goes in now, rather than staying open unseen.
    function adopt(notification) {
        if (notification.transient) {
            Qt.callLater(() => notification.expire()) // Toast-only, and the toast is gone
            return
        }

        root.setHistory([root.snapshot(notification), ...root.history])
    }

    // Removing an entry closes its notification, and with it the toast if
    // it's still on screen.
    function removeFromHistory(key) {
        const entry = root.history.find(e => e.key === key)

        root.history = root.history.filter(e => e.key !== key)
        entry?.live?.dismiss()
    }

    function clearHistory() {
        const live = root.history.map(entry => entry.live).filter(n => n)

        root.history = []

        for (const n of live) n.dismiss()
        for (const n of [...root.popups]) n.dismiss() // Transient toasts, never in the history
    }

    // Quickshell closes the notification itself once the reply is sent.
    function reply(notification, text) {
        if (!notification || text.length === 0) return

        root.replyingTo = null
        notification.sendInlineReply(text)
    }

    NotificationServer {
        id: server

        // Survive qs's live-reload instead of dropping the DBus registration.
        keepOnReload: true

        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        inlineReplySupported: true
        persistenceSupported: true

        onNotification: (notification) => {
            notification.tracked = true
            root.watch(notification)

            if (notification.lastGeneration) {
                root.relink(notification)
                return
            }

            // A warning replaces the one before it under the same key. Done
            // here as it arrives rather than when warn() sends it: one still
            // on its way at that point would slip past.
            const warning = root.warningKey(notification)
            if (warning !== "") root.clearWarning(warning)

            const quiet = root.dnd && notification.urgency !== NotificationUrgency.Critical

            // Transient ones are meant for the moment only: a toast, no history.
            if (!notification.transient) root.setHistory([root.snapshot(notification), ...root.history])

            if (!quiet) {
                root.popups = [...root.popups, notification]
            } else if (notification.transient) {
                Qt.callLater(() => notification.expire()) // Nowhere to show it
            }
        }
    }

    // Saved state: the history (without the live objects) and do not disturb.

    function stored(entry) {
        // Pictures sent as raw data are served from memory only while their
        // notification is open; after a restart the badge falls back to the
        // app's icon instead of a broken image.
        const image = entry.image ?? ""
        const lasting = image.startsWith("file://") || image.startsWith("/") || image.startsWith("image://icon/")

        return {
            key: entry.key,
            id: entry.id,
            appName: entry.appName,
            appIcon: entry.appIcon,
            image: lasting ? image : "",
            summary: entry.summary,
            body: entry.body,
            urgency: entry.urgency,
            warning: entry.warning,
            symbol: entry.symbol,
            time: entry.time.getTime()
        }
    }

    // `text` is empty when there's nothing saved yet.
    function restore(text) {
        let saved = {}
        if (text) {
            try {
                saved = JSON.parse(text)
            } catch (e) {
                console.warn("Notifications: couldn't read the saved history:", e)
            }
        }

        root.dnd = saved.dnd ?? root.dnd

        // After a live reload the server still holds the notifications it
        // had open, and may already have handed them over (see relink()):
        // link them back to their entries, so their actions keep working.
        const carried = [...server.trackedNotifications.values].filter(n => n.lastGeneration)

        const entries = (saved.history ?? []).map(entry => {
            const live = carried.find(n => n.id === entry.id && n.summary === entry.summary) ?? null
            return Object.assign({}, entry, { time: new Date(entry.time), live: live })
        })

        root.setHistory([...root.history, ...entries])
        root.restored = true

        for (const n of carried) {
            if (!root.history.some(entry => entry.live === n)) root.adopt(n)
        }

        save.restart() // Anything that arrived while loading
    }

    FileView {
        id: store

        path: Quickshell.statePath("notifications.json")
        printErrors: false // A missing file on first run is expected; the rest is reported below

        onLoaded: root.restore(store.text())

        // Nothing saved yet (first run): start from what the server has open.
        onLoadFailed: (error) => {
            if (error !== FileViewError.FileNotFound) console.warn("Notifications: couldn't load the saved history:", FileViewError.toString(error))
            root.restore("")
        }
    }

    // Batched: a burst of notifications writes once.
    Timer {
        id: save

        interval: 500
        onTriggered: store.setText(JSON.stringify({
            dnd: root.dnd,
            history: root.history.map(entry => root.stored(entry))
        }))
    }

    onHistoryChanged: if (root.restored) save.restart()
    onDndChanged: if (root.restored) save.restart()

    // `qs ipc call sidebar toggle` — bound to Super+N in Hyprland.
    IpcHandler {
        target: "sidebar"

        function toggle(): void { root.centerOpen = !root.centerOpen }
        function open(): void { root.centerOpen = true }
        function close(): void { root.centerOpen = false }
    }

    // `qs ipc call dnd toggle`
    IpcHandler {
        target: "dnd"

        function toggle(): void { root.dnd = !root.dnd }
        function on(): void { root.dnd = true }
        function off(): void { root.dnd = false }
    }
}
