// WindowsMenu.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

import qs.config
import qs.services
import qs.components

// An app's open windows, dropped from its icon in the bar to pick one. Drawn
// like the tray menus, and hangs like them: below the bar, centered on the
// icon but never past the bar's ends. Each row is a window's title and its
// workspace, with a dot on the one that has focus; clicking a row focuses
// that window.
//
// Esc closes it, and so does a click anywhere else.
PopupWindow {
    id: root

    required property Item anchorItem
    required property var app // An entry of Windows.apps

    // In the order they were opened, not by recency: by recency, the rows
    // would trade places every time one is picked.
    readonly property var windows: root.app
        ? Hyprland.toplevels.values.filter(toplevel => root.app.windows.includes(toplevel))
        : []

    // Where the icon sits in the bar, and the bar's size, taken on opening:
    // mapToItem() isn't something a binding can follow.
    property point origin
    property size area

    function toggle() {
        if (root.visible) {
            root.visible = false
            return
        }

        let top = root.anchorItem
        while (top.parent) top = top.parent

        root.origin = root.anchorItem.mapToItem(top, 0, 0)
        root.area = Qt.size(top.width, top.height)
        root.visible = true
    }

    function choose(toplevel) {
        Windows.focus(toplevel)
        root.visible = false
    }

    // Special workspaces are named "special:magic"; the prefix only takes room.
    function workspace(toplevel) {
        const name = toplevel.workspace?.name ?? ""
        return name.startsWith("special:") ? name.slice("special:".length) : name
    }

    grabFocus: true
    color: "transparent"

    implicitWidth: Math.ceil(Math.max(Settings.windows.menuMinWidth, Math.min(Settings.windows.menuMaxWidth,
        list.implicitWidth + container.leftPadding + container.rightPadding)))
    implicitHeight: container.implicitHeight

    anchor {
        item: root.anchorItem
        rect.x: Math.round(Math.max(0, Math.min(root.area.width - root.implicitWidth,
            root.origin.x + (root.anchorItem.width - root.implicitWidth) / 2)) - root.origin.x)
        rect.y: Math.round(root.area.height + Theme.margins - root.origin.y)
    }

    onVisibleChanged: {
        if (root.visible) {
            keys.forceActiveFocus()
            intro.restart()
        }
    }

    // The app quit with the list open: nothing left to pick.
    onWindowsChanged: {
        if (root.visible && root.windows.length === 0) root.visible = false
    }

    // Fades in while dropping a few pixels into place, like the tray menus.
    ParallelAnimation {
        id: intro

        NumberAnimation {
            target: container
            property: "opacity"
            from: 0
            to: 1
            duration: 140
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: slide
            property: "y"
            from: -Theme.spacing
            to: 0
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    PopupContainer {
        id: container

        width: parent.width
        radius: Theme.radiusCard

        transform: Translate {
            id: slide
        }

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
                    model: root.windows

                    delegate: Rectangle {
                        id: row

                        required property var modelData

                        readonly property bool focused: Windows.active === row.modelData

                        Layout.fillWidth: true
                        implicitWidth: content.implicitWidth + Theme.paddings * 2
                        implicitHeight: 36
                        radius: Theme.radius

                        color: cursor.containsMouse ? Theme.colors.hover : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        RowLayout {
                            id: content

                            anchors.fill: parent
                            anchors.leftMargin: Theme.paddings
                            anchors.rightMargin: Theme.paddings

                            spacing: Theme.paddings

                            // The window with focus: an accent dot. The column
                            // stays on every row so the titles line up.
                            Item {
                                implicitWidth: 6
                                implicitHeight: 6

                                Rectangle {
                                    anchors.fill: parent
                                    visible: row.focused

                                    radius: width / 2
                                    color: Theme.colors.accent
                                }
                            }

                            Text {
                                Layout.fillWidth: true

                                text: Windows.shortTitle(row.modelData)
                                elide: Text.ElideRight
                                color: Theme.colors.fg

                                font.family: Theme.font.family
                                font.pixelSize: Theme.font.size
                                font.weight: row.focused ? Font.Medium : Font.Normal
                            }

                            // Its workspace, in a small square like the
                            // workspaces widget's.
                            Rectangle {
                                visible: workspace.text !== ""

                                implicitWidth: Math.max(implicitHeight, workspace.implicitWidth + Theme.spacing * 2)
                                implicitHeight: 20
                                radius: Theme.edges

                                color: Theme.colors.hover

                                Text {
                                    id: workspace

                                    anchors.centerIn: parent

                                    text: root.workspace(row.modelData)
                                    color: Theme.colors.muted

                                    font.family: Theme.font.family
                                    font.pixelSize: Theme.font.small
                                }
                            }
                        }

                        MouseArea {
                            id: cursor

                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: root.choose(row.modelData)
                        }
                    }
                }
            }
        }
    }
}
