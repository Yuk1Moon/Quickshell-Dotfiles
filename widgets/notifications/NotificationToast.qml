// NotificationToast.qml

import QtQuick

import qs.config
import qs.components
import qs.services

// A notification as it arrives: the same card content as the sidebar history,
// on a floating popup with the gradient border. Critical ones get the same
// accent tint as in the history.
PopupContainer {
    id: root

    required property var notification

    // Toasts only exist while their notification is fresh, so creation time
    // is arrival time.
    readonly property date received: new Date()

    // Auto-dismiss, unless the sender asked to keep it around (expireTimeout: 0).
    readonly property real timeout: notification.expireTimeout === 0
        ? 0
        : (notification.expireTimeout > 0 ? notification.expireTimeout : Settings.notifications.timeout)

    implicitWidth: Settings.notifications.width
    radius: Theme.radiusCard
    tint: content.urgent ? Theme.colors.container : "transparent"

    // Paused while the pointer is over the toast, so it doesn't vanish
    // mid-read, and while a reply is being typed; starts over in full after.
    HoverHandler {
        id: hover

        parent: root
    }

    // Takes it off the screen; the notification itself stays open in the
    // history, with its actions (see Notifications.hidePopup).
    Timer {
        interval: root.timeout
        running: root.timeout > 0 && !hover.hovered && !content.replying
        onTriggered: Notifications.hidePopup(root.notification)
    }

    NotificationContent {
        id: content

        width: parent.width

        notification: root.notification
        live: root.notification
        time: root.received

        onCloseRequested: root.notification.dismiss()
    }
}
