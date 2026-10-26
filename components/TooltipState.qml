// TooltipState.qml
pragma Singleton

import Quickshell
import QtQuick

import qs.config

// What every Tooltip shares: which one is on screen, so there's only ever one,
// and when the last one went away, so sliding the pointer along the bar swaps
// tooltips at once instead of waiting out the delay on each widget.
Singleton {
    id: root

    property QtObject current: null // Cleared by itself if that tooltip is destroyed
    property double hiddenAt: 0 // Date.now() when the last one hid

    // A plain function, not a binding: Date.now() isn't something QML can
    // track, and it only matters at the moment a tooltip asks.
    function warm() {
        return root.current !== null || Date.now() - root.hiddenAt < Settings.tooltip.grace
    }

    function show(tooltip) {
        root.current = tooltip
    }

    function hide(tooltip) {
        if (root.current !== tooltip) return

        root.current = null
        root.hiddenAt = Date.now()
    }
}
