// PowerButton.qml

import QtQuick

import qs.components
import qs.services
import qs.widgets.powerMenu

IconButton {
    id: root

    icon: "power_settings_new"
    checked: menu.visible

    onClicked: menu.visible = !menu.visible

    PowerMenu {
        id: menu

        anchorItem: root
    }

    // Lists what the menu offers, so it follows Lock showing up once a
    // locker is installed.
    Tooltip {
        target: root
        below: root
        active: !menu.visible

        // No-break spaces inside each option, so a line never ends between
        // "shut" and "down".
        readonly property string actions: menu.actions
            .map(action => action.label.toLowerCase().replace(/ /g, " "))
            .join(", ")

        icon: root.icon
        title: "Power"
        body: actions.charAt(0).toUpperCase() + actions.slice(1)
    }

    // The menu hangs off the sidebar; don't leave it open for the next time
    // the sidebar shows.
    Connections {
        target: Notifications

        function onCenterOpenChanged() {
            if (!Notifications.centerOpen) menu.visible = false
        }
    }
}
