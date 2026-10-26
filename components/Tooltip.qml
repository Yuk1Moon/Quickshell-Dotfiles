// Tooltip.qml

import QtQuick
import Quickshell

import qs.config

// A hover card (InfoCard, the toast-like card the OSD uses too).
//
// By default it hangs below the whole window its target lives in — for the
// bar, that puts it level with the toasts and the sidebar. Centered on the
// target, but never past the window's sides. Shows after
// Settings.tooltip.delay of hovering; while one is up, moving to the next
// widget swaps it at once. Never takes input: clicks go straight through to
// whatever is underneath.
PopupWindow {
    id: root

    // The item whose hover shows the tooltip.
    required property Item target

    // Hang below this item instead of below the whole window: for targets in
    // a tall window like the sidebar, where the window's bottom is far away.
    property Item below: null

    // False keeps it hidden, e.g. while the widget's own popup is open.
    property bool active: true

    // What the card shows; see InfoCard.
    property string icon
    property string image
    property string picture
    property bool alert: false
    property string title
    property string meta
    property string body
    property real progress: -1
    property color progressColor: Theme.colors.accent

    // Also off while the target's window is hidden (the sidebar closing under
    // the pointer): otherwise the tooltip would stay "shown" and pop back up
    // the next time that window opens.
    readonly property bool windowVisible: root.target.QsWindow?.window?.visible ?? true

    readonly property bool wanted: hover.hovered && root.active && root.title !== ""
        && root.windowVisible
    readonly property bool shown: TooltipState.current === root

    // Where the target sits in its window, the window's size and the edge to
    // hang from, taken each time the tooltip shows: mapToItem() isn't
    // something a binding can follow, and nothing moves while the pointer
    // rests on the target.
    property point origin
    property size area
    property real edge

    function show() {
        let top = root.target
        while (top.parent) top = top.parent

        const below = root.below ?? top

        root.origin = root.target.mapToItem(top, 0, 0)
        root.area = Qt.size(top.width, top.height)
        root.edge = below.mapToItem(top, 0, below.height).y

        TooltipState.show(root)
    }

    onWantedChanged: {
        if (root.wanted) {
            if (TooltipState.warm()) root.show()
            else delay.restart()
        } else {
            delay.stop()
            TooltipState.hide(root)
        }
    }

    Timer {
        id: delay

        interval: Settings.tooltip.delay
        onTriggered: root.show()
    }

    HoverHandler {
        id: hover

        parent: root.target
    }

    // Stays mapped until the fade-out is over.
    visible: root.shown || card.opacity > 0
    color: "transparent"

    // Empty input region: the pointer passes straight through, so a tooltip
    // still fading out never catches a click meant for the window below.
    mask: Region {}

    implicitWidth: Math.ceil(Math.max(Settings.tooltip.minWidth, Math.min(Settings.tooltip.maxWidth, card.naturalWidth)))
    implicitHeight: Math.ceil(card.naturalHeight)

    // Centered under the target, clamped to the window's sides — for the bar,
    // its ends, which sit Theme.margins from the screen edges like the toasts
    // and the sidebar. Theme.margins below the edge it hangs from.
    anchor {
        item: root.target
        rect.x: Math.round(Math.max(0, Math.min(root.area.width - root.implicitWidth,
            root.origin.x + (root.target.width - root.implicitWidth) / 2)) - root.origin.x)
        rect.y: Math.round(root.edge + Theme.margins - root.origin.y)
    }

    InfoCard {
        id: card

        width: root.width
        height: root.height

        shown: root.shown

        icon: root.icon
        image: root.image
        picture: root.picture
        alert: root.alert
        title: root.title
        meta: root.meta
        body: root.body
        progress: root.progress
        progressColor: root.progressColor
    }
}
