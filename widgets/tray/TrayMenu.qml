// TrayMenu.qml

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.config
import qs.components

// A tray app's menu, dropped from its icon in the bar. The app sends the
// entries (DBusMenu) and they're drawn here like the power menu, instead of
// in Qt's default style. It hangs below the bar like the tooltips, centered on
// the icon but never past the bar's ends. A submenu replaces the list, with a
// row at the top to go back.
//
// Esc closes it, and so does a click anywhere else.
PopupWindow {
    id: root

    required property Item anchorItem
    required property var item // SystemTrayItem

    // Where the icon sits in the bar, and the bar's size, taken on opening:
    // mapToItem() isn't something a binding can follow.
    property point origin
    property size area

    // Submenus entered, innermost last.
    property var stack: []

    readonly property var submenu: root.stack.length > 0 ? root.stack[root.stack.length - 1] : null

    // The level on screen: the innermost submenu entered, or the menu itself.
    readonly property var opener: levels.instances.length > 0
        ? levels.instances[levels.instances.length - 1] : base
    readonly property var entries: root.opener.children?.values ?? []

    // Checkboxes and icons get a column of their own; when no entry has
    // either, labels start at the edge.
    readonly property bool lead: root.entries.some(entry =>
        entry.icon !== "" || entry.buttonType !== QsMenuButtonType.None)

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

    function activate(entry) {
        if (entry.hasChildren) {
            root.stack = [...root.stack, entry]
            return
        }

        entry.triggered()
        root.visible = false
    }

    function back() {
        root.stack = root.stack.slice(0, -1)
    }

    function symbol(entry) {
        const checked = entry.checkState === Qt.Checked

        switch (entry.buttonType) {
        case QsMenuButtonType.CheckBox:
            return checked ? "check_box" : "check_box_outline_blank"
        case QsMenuButtonType.RadioButton:
            return checked ? "radio_button_checked" : "radio_button_unchecked"
        }

        return ""
    }

    // Only while open: the app is asked to bring its menu up to date each
    // time it's loaded, and some only fill it in then.
    QsMenuOpener {
        id: base

        menu: root.visible ? root.item.menu : null
    }

    // Every submenu on the way down stays loaded too, one opener each:
    // letting go of a menu drops the entries in it, and the submenu being
    // shown is one of them. Variants keeps the openers of the levels that
    // are still there when one is added or removed.
    Variants {
        id: levels

        model: root.stack

        QsMenuOpener {
            required property var modelData

            menu: modelData
        }
    }

    grabFocus: true
    color: "transparent"

    implicitWidth: Math.ceil(Math.max(Settings.tray.menuMinWidth, Math.min(Settings.tray.menuMaxWidth,
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
        } else {
            root.stack = []
        }
    }

    // Fades in while dropping a few pixels into place, like the launcher.
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

                // Inside a submenu: its name, and the way back
                TrayMenuRow {
                    Layout.fillWidth: true
                    visible: root.submenu !== null

                    symbol: "arrow_back"
                    text: root.submenu?.text ?? ""
                    emphasized: true

                    onClicked: root.back()
                }

                HorizontalSeparator {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacing / 2
                    Layout.bottomMargin: Theme.spacing / 2
                    visible: root.submenu !== null
                }

                Repeater {
                    model: root.opener.children

                    delegate: Item {
                        id: entry

                        required property var modelData

                        Layout.fillWidth: true
                        implicitWidth: entry.modelData.isSeparator ? 0 : row.implicitWidth
                        implicitHeight: entry.modelData.isSeparator
                            ? separator.implicitHeight + Theme.spacing
                            : row.implicitHeight

                        HorizontalSeparator {
                            id: separator

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: entry.modelData.isSeparator
                        }

                        TrayMenuRow {
                            id: row

                            anchors.fill: parent
                            visible: !entry.modelData.isSeparator
                            enabled: entry.modelData.enabled

                            symbol: root.symbol(entry.modelData)
                            image: entry.modelData.icon
                            lead: root.lead
                            text: entry.modelData.text
                            trailing: entry.modelData.hasChildren ? "chevron_right" : ""

                            onClicked: root.activate(entry.modelData)
                        }
                    }
                }
            }
        }
    }
}
