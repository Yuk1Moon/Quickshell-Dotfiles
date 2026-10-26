// Windows.qml

pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

import qs.config

Singleton {
    id: root

    // Hyprland.activeToplevel stays null until the first activewindow event of
    // the session, which would leave nothing highlighted on a fresh start. The
    // per-window `wayland.activated` flag is right from the first frame instead.
    readonly property var active: {
        for (const toplevel of Hyprland.toplevels.values) {
            if (toplevel.wayland && toplevel.wayland.activated) return toplevel
        }

        return null
    }

    // Addresses of windows focused since the shell started, most recent first.
    property var order: []

    // Open windows, most recently focused first.
    readonly property var recent: {
        const open = Hyprland.toplevels.values

        const byAddress = {}
        for (const toplevel of open) byAddress[toplevel.address] = toplevel

        const ordered = []
        for (const address of root.order) {
            if (byAddress[address]) ordered.push(byAddress[address])
        }

        // Windows not yet focused in this session fall back to Hyprland's own
        // focus history (focusHistoryID 0 = most recent). That's what makes the
        // order correct on the first frame, for windows that were already open
        // before the shell started.
        const rest = open
            .filter(toplevel => !root.order.includes(toplevel.address))
            .sort((a, b) => root.historyId(a) - root.historyId(b))

        return [...ordered, ...rest]
    }

    // Open apps, most recently focused first: the windows grouped by app id,
    // each app where its most recently focused window is, so two kitty
    // windows share one slot. Each is { id, windows }, windows most recent
    // first. Capped at the number of slots the widget draws.
    readonly property var apps: {
        const groups = []
        const byId = {}

        for (const toplevel of root.recent) {
            const id = root.appId(toplevel)

            if (!byId[id]) {
                byId[id] = { id: id, windows: [] }
                groups.push(byId[id])
            }

            byId[id].windows.push(toplevel)
        }

        return groups.slice(0, Settings.windows.limit)
    }

    // What windows are grouped by. The Wayland handle can show up a moment
    // after the window does, so Hyprland's class covers that gap; a window
    // with neither stays on its own.
    function appId(toplevel) {
        return toplevel.wayland?.appId || toplevel.lastIpcObject?.class || toplevel.address
    }

    // focusHistoryID only reflects the moment the IPC object was last fetched,
    // so it seeds the order but doesn't maintain it — `order` does that.
    function historyId(toplevel) {
        const ipc = toplevel.lastIpcObject
        return ipc && ipc.focusHistoryID !== undefined ? ipc.focusHistoryID : 9999
    }

    // Desktop entries are scanned in the background when the shell starts,
    // and heuristicLookup() is a plain call a binding can't watch: a window
    // looked up before the scan finished kept a generic icon and its raw app
    // id for good. Reading the entry list first makes every binding that goes
    // through here run again once it fills in.
    function entry(toplevel) {
        if (!toplevel?.wayland || DesktopEntries.applications.values.length === 0) return null

        return DesktopEntries.heuristicLookup(toplevel.wayland.appId)
    }

    // Name and icon from the app's desktop entry, falling back to the raw
    // app id and a generic icon when there's no entry to go by.
    function appName(toplevel) {
        return root.entry(toplevel)?.name ?? toplevel?.wayland?.appId ?? ""
    }

    function appIcon(toplevel) {
        if (!toplevel?.wayland) return ""

        const entry = root.entry(toplevel)
        return Quickshell.iconPath(entry ? entry.icon : "", "application-x-executable")
    }

    // The window's title without the " - Brave" most apps end it with: next to
    // the app's own icon, or in a list of one app's windows, that part says
    // nothing. Titles that are only the app's name stay as they are.
    function shortTitle(toplevel) {
        const title = toplevel?.title ?? ""
        const name = root.appName(toplevel)

        for (const dash of [" - ", " — ", " – "]) {
            const suffix = dash + name
            if (name !== "" && title.length > suffix.length && title.endsWith(suffix)) {
                return title.slice(0, -suffix.length)
            }
        }

        return title || name
    }

    function touch(address) {
        if (!address) return

        // Drop windows that have closed since, so `order` stays bounded by the
        // number of open windows instead of growing for the whole session.
        const open = Hyprland.toplevels.values.map(toplevel => toplevel.address)

        root.order = [
            address,
            ...root.order.filter(a => a !== address && open.includes(a))
        ]
    }

    // Hyprland is configured in Lua here, and `hyprctl dispatch` parses what it
    // gets as Lua — so the classic `focuswindow address:0x...` string fails
    // silently (verified: "')' expected near 'address'"). The foreign-toplevel
    // `wayland.activate()` is ignored by the compositor too, so focusing goes
    // through the Lua dispatcher.
    function focus(toplevel) {
        if (!toplevel) return

        Hyprland.dispatch(
            'hl.dsp.focus({ window = "address:0x' + toplevel.address + '" })'
        )
    }

    onActiveChanged: {
        if (root.active) root.touch(root.active.address)
    }

    // `toplevels` stays empty until Hyprland answers, and nothing requests it
    // on its own — without this the widget is blank for the first moments.
    Component.onCompleted: Hyprland.refreshToplevels()
}
