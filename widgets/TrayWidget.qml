// TrayWidget.qml

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.SystemTray

import qs.config
import qs.components
import qs.widgets.tray

// The system tray: icons of the apps running in the background (Steam,
// Discord...). Left click opens the app, right click its menu, middle click
// its secondary action, and scrolling goes to the app. Hidden while no app
// has an icon.
PillContainer {
    id: root

    visible: SystemTray.items.values.length > 0

    // The icon menu open right now, if any: one at a time, and the other
    // icons' tooltips stay off so they don't land on top of it.
    property var openMenu: null

    RowLayout {
        anchors.verticalCenter: parent.verticalCenter

        spacing: Theme.spacing

        Repeater {
            model: SystemTray.items

            delegate: Rectangle {
                id: slot

                required property var modelData

                readonly property bool attention: slot.modelData.status === Status.NeedsAttention

                implicitWidth: 24
                implicitHeight: 24
                radius: Theme.edges

                color: cursor.containsMouse || menu.visible ? Theme.colors.hover : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                IconImage {
                    anchors.centerIn: parent

                    implicitSize: 16
                    source: slot.modelData.icon
                }

                // The app asking for attention: an accent dot in the corner.
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    visible: slot.attention

                    implicitWidth: 6
                    implicitHeight: 6
                    radius: width / 2

                    color: Theme.colors.accent
                }

                MouseArea {
                    id: cursor

                    anchors.fill: parent

                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: (mouse) => {
                        const item = slot.modelData

                        if (mouse.button === Qt.MiddleButton) item.secondaryActivate()
                        // Some apps have nothing to open but the menu.
                        else if (item.hasMenu && (mouse.button === Qt.RightButton || item.onlyMenu)) menu.toggle()
                        else if (mouse.button === Qt.LeftButton) item.activate()
                    }

                    onWheel: (wheel) => {
                        const horizontal = wheel.angleDelta.y === 0
                        slot.modelData.scroll(horizontal ? wheel.angleDelta.x : wheel.angleDelta.y, horizontal)
                    }
                }

                TrayMenu {
                    id: menu

                    anchorItem: slot
                    item: slot.modelData

                    onVisibleChanged: {
                        if (menu.visible) {
                            if (root.openMenu) root.openMenu.visible = false
                            root.openMenu = menu
                        } else if (root.openMenu === menu) {
                            root.openMenu = null
                        }
                    }
                }

                // Whatever the app puts in its own tooltip, falling back to its name.
                Tooltip {
                    target: slot
                    active: root.openMenu === null

                    image: slot.modelData.icon
                    alert: slot.attention

                    title: slot.modelData.tooltipTitle || slot.modelData.title || slot.modelData.id
                    body: slot.modelData.tooltipDescription
                }
            }
        }
    }
}
