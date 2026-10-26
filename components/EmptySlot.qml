// EmptySlot.qml

import QtQuick

import qs.config

// Placeholder circle for a control that doesn't exist yet: holds its place in
// the layout without pretending to do anything.
Rectangle {
    id: root

    property int size: 32

    implicitWidth: root.size
    implicitHeight: root.size
    radius: width / 2

    color: Qt.alpha(Theme.colors.muted, 0.2)
}
