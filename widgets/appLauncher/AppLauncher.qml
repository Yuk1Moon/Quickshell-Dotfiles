// AppLauncher.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

import qs.config
import qs.components

// The app launcher, dropped from its bar button. Built like the sidebar it
// mirrors on the other side of the screen: same panel, its top edge level
// with the sidebar's and its left edge lined up with the bar's; a pill search
// field, the apps as cards inside a section like the notifications', and a
// footer with the count.
//
// Keyboard: type to filter, Up/Down to move, Enter to launch, Esc to close.
PopupWindow {
    id: root

    required property Item anchorItem

    // Where the button sits in the bar, and the bar's height, taken on
    // opening: mapToItem() isn't something a binding can follow.
    property point origin
    property real barHeight

    // The one Enter launches.
    property int current: 0

    function toggle() {
        if (root.visible) {
            root.visible = false
            return
        }

        let top = root.anchorItem
        while (top.parent) top = top.parent

        root.origin = root.anchorItem.mapToItem(top, 0, 0)
        root.barHeight = top.height
        root.visible = true
    }

    function launch(app) {
        if (!app) return

        app.execute()
        root.visible = false
    }

    function move(delta) {
        if (root.apps.length === 0) return

        root.current = Math.max(0, Math.min(root.apps.length - 1, root.current + delta))
        list.positionViewAtIndex(root.current, ListView.Contain)
    }

    // Everything, alphabetically, until something is typed. Then best match
    // first: the name starting with the query, then a word in it starting
    // with it, then the name containing it anywhere, then only its generic
    // name or keywords ("browser" finds Brave).
    readonly property var apps: {
        const query = search.text.trim().toLowerCase()
        const all = [...DesktopEntries.applications.values]

        // Lowercased first: the system locale is C, where a plain compare
        // puts "kitty" after "XAMPP".
        const byName = (a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase())

        if (query === "") return all.sort(byName)

        const rank = app => {
            const name = app.name.toLowerCase()

            if (name.startsWith(query)) return 0
            if (name.split(/[\s\-_.]+/).some(word => word.startsWith(query))) return 1
            if (name.includes(query)) return 2
            if ((app.genericName ?? "").toLowerCase().includes(query)) return 3
            if ([...(app.keywords ?? [])].some(keyword => keyword.toLowerCase().includes(query))) return 3
            return -1
        }

        return all
            .map(app => ({ app: app, rank: rank(app) }))
            .filter(match => match.rank >= 0)
            .sort((a, b) => a.rank - b.rank || byName(a.app, b.app))
            .map(match => match.app)
    }

    onAppsChanged: {
        root.current = 0
        list.positionViewAtBeginning()
    }

    implicitWidth: Settings.appLauncher.width
    implicitHeight: Settings.appLauncher.height

    grabFocus: true
    color: "transparent"

    anchor {
        item: root.anchorItem
        rect.x: -root.origin.x
        rect.y: root.barHeight + Theme.margins - root.origin.y
    }

    onVisibleChanged: {
        if (root.visible) {
            search.forceActiveFocus()
            intro.restart()
        } else {
            search.text = ""
        }
    }

    // Fades in while dropping a few pixels into place, like the tooltips.
    ParallelAnimation {
        id: intro

        NumberAnimation {
            target: panel
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
        id: panel

        anchors.fill: parent

        padding: Settings.appLauncher.padding
        radius: Theme.radiusPanel

        transform: Translate {
            id: slide
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Settings.appLauncher.spacing

            // Search: a pill like the Wi-Fi password field
            TextField {
                id: search

                Layout.fillWidth: true
                implicitHeight: 40

                leftPadding: searchIcon.width + Theme.paddings * 2
                rightPadding: clear.visible ? clear.width + Theme.paddings : Theme.paddings * 2

                placeholderText: "What's the matter..."
                placeholderTextColor: Theme.colors.muted

                color: Theme.colors.fg
                selectionColor: Theme.colors.accent

                font.family: Theme.font.family
                font.pixelSize: Theme.font.size

                background: Rectangle {
                    color: Theme.colors.surfaceHigh
                    radius: height / 2

                    border.width: search.activeFocus ? 2 : 1
                    border.color: search.activeFocus ? Theme.colors.selected : Theme.colors.muted

                    Behavior on border.color {
                        ColorAnimation { duration: 120 }
                    }
                }

                Keys.onUpPressed: root.move(-1)
                Keys.onDownPressed: root.move(1)
                Keys.onEscapePressed: root.visible = false
                onAccepted: root.launch(root.apps[root.current])

                Text {
                    id: searchIcon

                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddings + Theme.spacing
                    anchors.verticalCenter: parent.verticalCenter

                    text: "search"
                    color: Theme.colors.muted

                    font.family: Theme.font.icons
                    font.pixelSize: Theme.font.medium
                }

                IconButton {
                    id: clear

                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacing + Theme.spacing / 2
                    anchors.verticalCenter: parent.verticalCenter

                    visible: search.text.length > 0

                    size: 28
                    icon: "close"

                    onClicked: search.text = ""
                }
            }

            // The apps, in a section like the sidebar's notifications
            CardContainer {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: list

                    anchors.fill: parent
                    visible: root.apps.length > 0

                    clip: true
                    spacing: Theme.pVertical

                    model: ScriptModel {
                        values: root.apps
                    }

                    delegate: AppEntry {
                        required property var modelData
                        required property int index

                        width: ListView.view.width

                        app: modelData
                        current: index === root.current

                        onActivated: root.launch(modelData)
                    }
                }

                // Empty state
                Column {
                    anchors.centerIn: parent
                    visible: root.apps.length === 0

                    spacing: Theme.spacing

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: "search_off"
                        color: Theme.colors.muted

                        font.family: Theme.font.icons
                        font.pixelSize: Theme.font.large * 2
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: "No apps found"
                        color: Theme.colors.muted

                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.size
                    }
                }
            }

            // Footer: count, and the keys
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacing
                Layout.rightMargin: Theme.spacing

                Text {
                    Layout.fillWidth: true

                    text: root.apps.length === 1 ? "1 app" : root.apps.length + " apps"
                    color: Theme.colors.fg

                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.size
                    font.weight: Font.Medium
                }

                Text {
                    text: "↑↓ move · Enter open"
                    color: Theme.colors.muted

                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.small
                }
            }
        }
    }
}
