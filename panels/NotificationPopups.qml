// NotificationPopups.qml

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.services
import qs.widgets.notifications

Scope {
    PanelWindow {
        id: root

        color: "transparent"

        // Purely a floating overlay — don't reserve screen space like the bar does.
        exclusionMode: ExclusionMode.Ignore

        // Keyboard only while a reply is being typed: the rest of the time the
        // toasts shouldn't take focus away from the window behind.
        WlrLayershell.keyboardFocus: Notifications.replyingTo !== null
            ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Explicit, tied to the data instead of a derived size — a layer-shell
        // surface that shrinks to 0 height when it empties out can get
        // unmapped by the compositor and fail to reappear on the next toast.
        //
        // Hidden while the sidebar is open: it sits in the same corner, and
        // its history already shows every new notification.
        visible: Notifications.popups.length > 0 && !Notifications.centerOpen

        anchors {
            top: true
            right: true
        }

        // Same edges as the sidebar: below the bar, and Theme.margins (Hyprland's
        // gaps_out) from the screen edge.
        margins {
            top: Theme.margins + Settings.bar.height + Theme.margins
            right: Theme.margins
        }

        implicitWidth: Settings.notifications.width
        implicitHeight: Math.max(1, column.implicitHeight)

        ColumnLayout {
            id: column

            width: parent.width
            spacing: Theme.paddings

            Repeater {
                model: ScriptModel {
                    values: Notifications.popups
                }

                delegate: NotificationToast {
                    required property var modelData

                    Layout.fillWidth: true

                    notification: modelData
                }
            }
        }
    }
}
