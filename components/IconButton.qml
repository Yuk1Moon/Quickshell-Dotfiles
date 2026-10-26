// IconButton.qml

import QtQuick

import qs.config

// Round icon-only button: transparent (or `baseColor`) until hovered, filled
// with the accent while `checked`. Dims itself when disabled.
Rectangle {
    id: root

    property string icon
    property int size: 32
    property int iconSize: Theme.font.medium
    property bool checked: false
    property color baseColor: "transparent"
    property color iconColor: root.checked ? Theme.colors.onAccent : Theme.colors.fg

    // Off by default so a button sitting in a list doesn't swallow the
    // list's scrolling.
    property bool scrollable: false

    signal clicked()
    signal scrolled(int direction) // +1 up, -1 down

    implicitWidth: root.size
    implicitHeight: root.size
    radius: width / 2

    color: root.checked ? Theme.colors.accent : root.baseColor
    opacity: root.enabled ? 1 : 0.4

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius

        color: Theme.colors.hover
        opacity: cursor.containsMouse ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    Text {
        anchors.centerIn: parent

        text: root.icon
        color: root.iconColor

        font.family: Theme.font.icons
        font.pixelSize: root.iconSize
    }

    MouseArea {
        id: cursor

        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
        onWheel: (wheel) => {
            if (!root.scrollable) {
                wheel.accepted = false
                return
            }
            root.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
        }
    }
}
