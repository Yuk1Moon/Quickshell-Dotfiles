// CardContainer.qml

import QtQuick
import QtQuick.Controls

import qs.config

// A section inside a panel. Sized by the layout it sits in, never by its
// content: children fill it, and deriving the implicit size from them would
// feed the size back into itself (same loop BarContainer had).
Control {
    id: root

    property color color: Theme.colors.surfaceMid
    property real radius: Theme.radiusCard

    default property alias content: container.data

    padding: Theme.paddings

    contentItem: Item {
        id: container
    }

    background: Rectangle {
        color: root.color
        radius: root.radius
    }
}
