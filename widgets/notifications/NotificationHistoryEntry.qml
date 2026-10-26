// NotificationHistoryEntry.qml

import QtQuick
import QtQuick.Controls

import qs.config
import qs.services

// One notification in the sidebar history: the shared card content on a
// plain card, with the actions and reply while the sender still has it open.
// Critical ones get an accent-tinted card.
Control {
    id: root

    required property var notification // A snapshot from Notifications.history

    hoverEnabled: true
    padding: Theme.paddings

    background: Rectangle {
        radius: Theme.radius
        color: content.urgent ? Theme.colors.container : Theme.colors.surface

        Rectangle {
            anchors.fill: parent
            radius: parent.radius

            color: Theme.colors.hover
            opacity: root.hovered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
        }
    }

    contentItem: NotificationContent {
        id: content

        notification: root.notification
        live: root.notification.live
        time: root.notification.time

        onCloseRequested: Notifications.removeFromHistory(root.notification.key)
    }
}
