// NotificationHistory.qml

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.config
import qs.components
import qs.services

// The sidebar's notification area: the cards, an empty state, and a footer
// with the count and a clear-all button.
ColumnLayout {
    id: root

    readonly property int count: Notifications.history.length

    spacing: Theme.paddings

    // Empty state
    Item {
        visible: root.count === 0

        Layout.fillWidth: true
        Layout.fillHeight: true

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacing

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: "notifications_off"
                color: Theme.colors.muted

                font.family: Theme.font.icons
                font.pixelSize: Theme.font.large * 2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: "No notifications"
                color: Theme.colors.muted

                font.family: Theme.font.family
                font.pixelSize: Theme.font.size
            }
        }
    }

    ListView {
        visible: root.count > 0

        Layout.fillWidth: true
        Layout.fillHeight: true

        clip: true
        spacing: Theme.pVertical

        model: ScriptModel {
            values: Notifications.history
        }

        delegate: NotificationHistoryEntry {
            required property var modelData

            width: ListView.view.width
            notification: modelData
        }
    }

    // Footer
    RowLayout {
        visible: root.count > 0

        Layout.fillWidth: true
        Layout.leftMargin: Theme.spacing

        Text {
            Layout.fillWidth: true

            text: root.count === 1 ? "1 notification" : root.count + " notifications"
            color: Theme.colors.fg

            font.family: Theme.font.family
            font.pixelSize: Theme.font.size
            font.weight: Font.Medium
        }

        Rectangle {
            implicitWidth: clearRow.implicitWidth + Theme.paddings * 2
            implicitHeight: 28
            radius: height / 2

            color: clearCursor.containsMouse ? Theme.colors.hover : "transparent"

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            RowLayout {
                id: clearRow

                anchors.centerIn: parent
                spacing: Theme.spacing

                Text {
                    text: "clear_all"
                    color: Theme.colors.fg

                    font.family: Theme.font.icons
                    font.pixelSize: Theme.font.medium
                }

                Text {
                    text: "Clear"
                    color: Theme.colors.fg

                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.size
                }
            }

            MouseArea {
                id: clearCursor

                anchors.fill: parent

                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: Notifications.clearHistory()
            }
        }
    }
}
