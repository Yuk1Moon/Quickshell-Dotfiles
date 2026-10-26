// PowerMenu.qml

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.config
import qs.components
import qs.services

// Drop-down under the sidebar's power button. Lock and suspend run on the
// first click; log out, reboot and shut down ask for a second click, so a
// stray one can't end the session.
PopupWindow {
    id: root

    required property Item anchorItem

    // Right edges lined up with the button, just below it.
    anchor {
        item: root.anchorItem
        rect.x: root.anchorItem.width - root.implicitWidth
        rect.y: root.anchorItem.height + Theme.spacing
    }

    grabFocus: true
    color: "transparent"

    implicitWidth: 200
    implicitHeight: container.implicitHeight

    readonly property var actions: [
        { icon: "lock", label: "Lock", run: () => Session.lock(), available: Session.locker !== "" },
        { icon: "bedtime", label: "Suspend", run: () => Session.suspend() },
        { icon: "logout", label: "Log out", confirm: "Log out now?", run: () => Session.logout() },
        { icon: "restart_alt", label: "Reboot", confirm: "Reboot now?", run: () => Session.reboot() },
        { icon: "power_settings_new", label: "Shut down", confirm: "Shut down now?", run: () => Session.poweroff() }
    ].filter(action => action.available ?? true)

    // Index of the action waiting for its second click, -1 for none. Drops
    // back after a few seconds so an old half-click can't be finished later.
    property int confirming: -1

    function activate(index) {
        const action = root.actions[index]

        if (action.confirm && root.confirming !== index) {
            root.confirming = index
            confirmTimeout.restart()
            return
        }

        root.visible = false
        Notifications.centerOpen = false
        action.run()
    }

    onActionsChanged: root.confirming = -1

    onVisibleChanged: {
        root.confirming = -1
        if (root.visible) keys.forceActiveFocus()
    }

    Timer {
        id: confirmTimeout

        interval: 3000
        onTriggered: root.confirming = -1
    }

    PopupContainer {
        id: container

        width: parent.width
        radius: Theme.radiusCard

        Item {
            id: keys

            implicitWidth: list.implicitWidth
            implicitHeight: list.implicitHeight

            Keys.onEscapePressed: root.visible = false

            ColumnLayout {
                id: list

                width: root.implicitWidth - container.leftPadding - container.rightPadding
                spacing: Theme.spacing / 2

                Repeater {
                    model: root.actions

                    delegate: Rectangle {
                        id: row

                        required property var modelData
                        required property int index

                        readonly property bool confirming: root.confirming === row.index

                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: Theme.radius

                        color: row.confirming ? Theme.colors.accent
                            : cursor.containsMouse ? Theme.colors.hover
                            : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.paddings
                            anchors.rightMargin: Theme.paddings

                            spacing: Theme.paddings

                            Text {
                                text: row.modelData.icon
                                color: row.confirming ? Theme.colors.onAccent : Theme.colors.fg

                                font.family: Theme.font.icons
                                font.pixelSize: Theme.font.medium
                            }

                            Text {
                                Layout.fillWidth: true

                                text: row.confirming ? row.modelData.confirm : row.modelData.label
                                elide: Text.ElideRight
                                color: row.confirming ? Theme.colors.onAccent : Theme.colors.fg

                                font.family: Theme.font.family
                                font.pixelSize: Theme.font.size
                                font.weight: row.confirming ? Font.Medium : Font.Normal
                            }
                        }

                        MouseArea {
                            id: cursor

                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: root.activate(row.index)
                        }
                    }
                }
            }
        }
    }
}
