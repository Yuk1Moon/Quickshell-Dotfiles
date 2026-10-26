// NotificationCenterButton.qml

import QtQuick

import qs.config
import qs.services
import qs.components

PillContainer {
    id: root

    hoverable: true

    implicitWidth: 32
    implicitHeight: 32

    Text {
        anchors.centerIn: parent

        // Shows do not disturb while it's on, since no toast will say so.
        text: Notifications.dnd ? "do_not_disturb_on" : "deployed_code"
        color: Theme.colors.fg

        font.family: Theme.font.icons
        font.pixelSize: Theme.font.medium
    }

    MouseArea {
        parent: root
        anchors.fill: parent
        z: 1

        cursorShape: Qt.PointingHandCursor
        onClicked: Notifications.centerOpen = !Notifications.centerOpen
    }

    // Not while the sidebar is open: it would land on top of it.
    Tooltip {
        target: root
        active: !Notifications.centerOpen

        readonly property int count: Notifications.history.length

        readonly property string notifications: count === 0 ? "No notifications"
            : count === 1 ? "1 notification"
            : count + " notifications"

        icon: Notifications.dnd ? "do_not_disturb_on" : "deployed_code"
        title: "Control center"
        meta: Notifications.dnd ? "Do not disturb" : ""
        body: notifications
    }
}
