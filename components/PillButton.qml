// PillButton.qml

import QtQuick

import qs.config

// Text button shaped as a pill, same look as the notification action buttons.
Rectangle {
    id: root

    property string text

    signal clicked()

    implicitWidth: label.implicitWidth + Theme.paddings * 3
    implicitHeight: 32
    radius: height / 2

    color: cursor.containsMouse ? Theme.colors.container : Theme.colors.hover
    opacity: root.enabled ? 1 : 0.4

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Text {
        id: label

        anchors.centerIn: parent
        width: Math.min(implicitWidth, root.width - Theme.paddings * 2)

        text: root.text
        elide: Text.ElideRight
        color: Theme.colors.fg

        font.family: Theme.font.family
        font.pixelSize: Theme.font.small
    }

    MouseArea {
        id: cursor

        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
    }
}
