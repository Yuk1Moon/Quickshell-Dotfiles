// QuickToggle.qml

import QtQuick

import qs.config
import qs.components

// A round quick-settings button. On/off toggles fill with the accent while
// `checked`; level controls (volume, brightness) draw their level as a ring
// instead — same ring the bar's volume and brightness widgets use.
IconButton {
    id: root

    property real level: -1 // 0.0 - 1.0 draws a ring; -1 for none
    property color ringColor: Theme.colors.accent

    size: 32
    scrollable: true
    baseColor: Theme.colors.surfaceHigh

    RingIndicator {
        anchors.fill: parent
        visible: root.level >= 0

        progress: Math.max(0, root.level)
        color: root.ringColor
        thickness: 2.5
    }
}
