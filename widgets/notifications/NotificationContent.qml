// NotificationContent.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

import qs.config
import qs.components
import qs.services

// The inside of a notification card, shared by the toasts and the sidebar
// history so both look the same: round app icon, summary with the time it
// arrived, body clamped to two lines until expanded, and — while the sender
// still has the notification open — its action buttons and inline reply.
// The card around it is up to the caller.
ColumnLayout {
    id: root

    // Anything with appName / appIcon / image / summary / body / urgency: a
    // live Notification (toasts) or a snapshot from Notifications.history.
    required property var notification
    required property date time

    // The Notification object while its sender has it open: where the action
    // buttons and the inline reply come from. Null in history entries whose
    // notification has closed.
    property var live: null

    readonly property var actions: root.live?.actions ?? []
    readonly property bool canReply: root.live?.hasInlineReply ?? false
    readonly property bool replying: root.live !== null && Notifications.replyingTo === root.live

    onReplyingChanged: {
        if (root.replying) replyField.forceActiveFocus()
        else replyField.text = ""
    }

    property bool expanded: false

    readonly property bool urgent: root.notification.urgency === NotificationUrgency.Critical

    // What goes in the round badge, most specific first:
    //   1. a picture the sender attached (usually an avatar) fills the circle;
    //   2. otherwise an icon: the app's own, one passed as the image — what
    //      `notify-send -i` does, arriving as image://icon/<name> with an
    //      empty appIcon — or the one from the app's desktop entry;
    //   3. otherwise a symbol, instead of a blank square.
    // The shell's own warnings name their symbol instead (Notifications.warn):
    // a snapshot keeps it as `symbol`, a live one has it in its hints.
    readonly property string symbol: root.notification.symbol
        ?? root.notification.hints?.["x-quickshell-symbol"] ?? ""

    readonly property string image: root.notification.image ?? ""
    readonly property bool hasPicture: root.image !== ""
        && !root.image.startsWith("image://icon/")
        && picture.status !== Image.Error

    readonly property string iconSource: {
        if (root.symbol !== "") return ""

        const icon = root.notification.appIcon
        if (icon.length > 0) {
            if (icon.startsWith("/")) return "file://" + icon
            if (icon.includes("://")) return icon

            const path = Quickshell.iconPath(icon, true)
            if (path !== "") return path
        }

        if (root.image.startsWith("image://icon/")) return root.image

        const entry = DesktopEntries.heuristicLookup(root.notification.appName ?? "")
        if (entry && entry.icon) return Quickshell.iconPath(entry.icon, true)

        return ""
    }

    // "21:48" today, "Yesterday", "22 Sep" before that. Follows Time.now,
    // so labels roll over at midnight.
    readonly property string timeLabel: {
        const now = Time.now
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        const day = new Date(root.time.getFullYear(), root.time.getMonth(), root.time.getDate())
        const days = Math.round((today - day) / 86400000)

        if (days === 0) return Qt.formatTime(root.time, "hh:mm")
        if (days === 1) return "Yesterday"
        return root.time.toLocaleDateString(Qt.locale(Settings.calendar.locale), "d MMM")
    }

    signal closeRequested()

    spacing: Theme.paddings

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.paddings

        // App icon badge
        Rectangle {
            Layout.alignment: Qt.AlignTop

            implicitWidth: 36
            implicitHeight: 36
            radius: width / 2

            color: root.urgent ? Theme.colors.accent : Theme.colors.hover

            ClippingRectangle {
                anchors.fill: parent
                visible: root.hasPicture

                radius: width / 2
                color: "transparent"

                Image {
                    id: picture

                    anchors.fill: parent

                    source: root.image.startsWith("image://icon/") ? "" : root.image
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2
                }
            }

            IconImage {
                anchors.centerIn: parent
                visible: !root.hasPicture && root.iconSource !== ""

                implicitSize: 20
                source: root.iconSource
            }

            Text {
                anchors.centerIn: parent
                visible: !root.hasPicture && root.iconSource === ""

                text: root.symbol !== "" ? root.symbol
                    : root.urgent ? "priority_high" : "notifications"
                color: root.urgent ? Theme.colors.onAccent : Theme.colors.fg

                font.family: Theme.font.icons
                font.pixelSize: Theme.font.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop

            spacing: Theme.spacing / 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing

                Text {
                    Layout.fillWidth: true

                    text: root.notification.summary
                    elide: Text.ElideRight
                    color: Theme.colors.fg

                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.size
                    font.weight: Font.Medium
                }

                // Time, expand and close, placed by hand rather than by the
                // row. The expand button comes and goes with `body.truncated`;
                // if that relaid the row it would resize the body and flip
                // `truncated` back — an endless polish loop that froze the
                // whole shell on any one-line body. The cluster is always as
                // wide as its widest state, so only positions inside it move,
                // and the time sits right next to whichever button is showing.
                Item {
                    implicitWidth: time.implicitWidth + Theme.spacing + closeButton.size * 2
                    implicitHeight: closeButton.size

                    IconButton {
                        id: closeButton

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        size: 24
                        icon: "close"

                        onClicked: root.closeRequested()
                    }

                    IconButton {
                        id: expandButton

                        anchors.right: closeButton.left
                        anchors.rightMargin: Theme.spacing
                        anchors.verticalCenter: parent.verticalCenter

                        visible: body.truncated || root.expanded

                        size: 24
                        icon: root.expanded ? "expand_less" : "expand_more"

                        onClicked: root.expanded = !root.expanded
                    }

                    // No margin: the button's round hover area around its
                    // glyph already leaves a gap, and adding spacing on top
                    // pushed the time visibly away from the X.
                    Text {
                        id: time

                        anchors.right: expandButton.visible ? expandButton.left : closeButton.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: root.timeLabel
                        color: Theme.colors.muted

                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.small
                    }
                }
            }

            Text {
                id: body

                Layout.fillWidth: true
                visible: root.notification.body.length > 0

                text: root.notification.body
                wrapMode: Text.Wrap
                maximumLineCount: root.expanded ? 1000 : 2
                elide: Text.ElideRight
                color: Theme.colors.muted

                font.family: Theme.font.family
                font.pixelSize: Theme.font.small
            }
        }
    }

    // Action buttons, as full-width pills sharing the row; Reply first when
    // the sender takes inline replies.
    RowLayout {
        visible: (root.actions.length > 0 || root.canReply) && !root.replying

        Layout.fillWidth: true
        spacing: Theme.spacing

        Repeater {
            model: root.canReply ? [{ text: "Reply", reply: true }, ...root.actions] : root.actions

            delegate: Rectangle {
                id: action

                required property var modelData

                Layout.fillWidth: true

                implicitHeight: 28
                radius: height / 2

                color: actionCursor.containsMouse ? Theme.colors.container : Theme.colors.hover

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                Text {
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, parent.width - Theme.paddings * 2)

                    text: action.modelData.text
                    elide: Text.ElideRight
                    color: Theme.colors.fg

                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.small
                }

                MouseArea {
                    id: actionCursor

                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (action.modelData.reply) Notifications.replyingTo = root.live
                        else action.modelData.invoke()
                    }
                }
            }
        }
    }

    // Inline reply, in place of the buttons while it's open. A pill like the
    // Wi-Fi password field; Enter or the arrow sends, Esc gives up.
    TextField {
        id: replyField

        visible: root.replying

        Layout.fillWidth: true
        implicitHeight: 32

        leftPadding: Theme.paddings
        rightPadding: send.width + Theme.spacing

        placeholderText: root.live?.inlineReplyPlaceholder || "Reply"
        placeholderTextColor: Theme.colors.muted

        color: Theme.colors.fg
        selectionColor: Theme.colors.accent

        font.family: Theme.font.family
        font.pixelSize: Theme.font.small

        background: Rectangle {
            color: Theme.colors.surfaceHigh
            radius: height / 2

            border.width: replyField.activeFocus ? 2 : 1
            border.color: replyField.activeFocus ? Theme.colors.selected : Theme.colors.muted

            Behavior on border.color {
                ColorAnimation { duration: 120 }
            }
        }

        onAccepted: Notifications.reply(root.live, replyField.text)
        Keys.onEscapePressed: Notifications.replyingTo = null

        IconButton {
            id: send

            anchors.right: parent.right
            anchors.rightMargin: Theme.spacing
            anchors.verticalCenter: parent.verticalCenter

            enabled: replyField.text.length > 0

            size: 24
            iconSize: Theme.font.size
            icon: "send"

            onClicked: Notifications.reply(root.live, replyField.text)
        }
    }
}
