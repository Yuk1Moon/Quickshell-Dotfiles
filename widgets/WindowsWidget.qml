// WindowsWidget.qml

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.config
import qs.services
import qs.components
import qs.widgets.windows

// The open apps, one slot each. Clicking an app with one window focuses it;
// with several, it drops the list of them to pick one (WindowsMenu). Right
// click always drops the list.
PillContainer {
    id: root

    // The window list open right now, if any: one at a time, and the
    // tooltips stay off so they don't land on top of it.
    property var openMenu: null

    RowLayout {
        spacing: Theme.spacing
        anchors.verticalCenter: parent.verticalCenter

        // A fixed count of slots, not one per open app — see
        // Settings.windows.limit for why.
        Repeater {
            model: Settings.windows.limit

            delegate: Rectangle {
                id: slot

                required property int index

                // One app per slot, with all its windows (see Windows.apps).
                readonly property var app: Windows.apps[index] ?? null
                readonly property string appId: slot.app?.id ?? ""
                readonly property int count: slot.app?.windows.length ?? 0

                // Its most recently focused window: the one the icon and the
                // tooltip go by.
                readonly property var toplevel: slot.app?.windows[0] ?? null

                readonly property bool active: slot.app !== null
                    && slot.app.windows.includes(Windows.active)
                readonly property string iconSource: Windows.appIcon(slot.toplevel)

                implicitWidth: 24
                implicitHeight: 24
                radius: Theme.edges

                // `selected` rather than `fg` like the workspaces widget uses:
                // an app icon sitting on a near-white fill washes out, while the
                // workspace numbers just invert their text color.
                color: slot.active
                    ? Theme.colors.selected
                    : (cursor.containsMouse && slot.toplevel) || menu.visible
                        ? Theme.colors.hover : "transparent"

                // Another app moving into this slot (a window opening, focus
                // changing) would leave the list showing its windows instead.
                onAppIdChanged: menu.visible = false

                // Empty slots keep a marker so the row reads as a fixed set of
                // five instead of a ragged gap.
                Rectangle {
                    anchors.centerIn: parent
                    visible: !slot.toplevel

                    implicitWidth: 6
                    implicitHeight: 6
                    radius: width / 2
                    color: Qt.alpha(Theme.colors.muted, 0.35)
                }

                IconImage {
                    anchors.centerIn: parent
                    visible: slot.toplevel !== null

                    implicitSize: 16
                    source: slot.iconSource
                }

                // An app with more than one window gets a dot per window under
                // its icon, like a dock. Three at most; the tooltip has the count.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    visible: slot.count > 1

                    spacing: 2

                    Repeater {
                        model: Math.min(slot.count, 3)

                        delegate: Rectangle {
                            implicitWidth: 3
                            implicitHeight: 3
                            radius: width / 2
                            color: Theme.colors.fg
                        }
                    }
                }

                MouseArea {
                    id: cursor

                    anchors.fill: parent

                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: slot.toplevel
                        ? Qt.PointingHandCursor : Qt.ArrowCursor

                    onClicked: (mouse) => {
                        if (!slot.toplevel) return

                        if (mouse.button === Qt.RightButton || slot.count > 1) menu.toggle()
                        else Windows.focus(slot.toplevel)
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                WindowsMenu {
                    id: menu

                    anchorItem: slot
                    app: slot.app

                    onVisibleChanged: {
                        if (menu.visible) {
                            if (root.openMenu) root.openMenu.visible = false
                            root.openMenu = menu
                        } else if (root.openMenu === menu) {
                            root.openMenu = null
                        }
                    }
                }

                // One window: its title, and which app and workspace it belongs
                // to. Several: the app, how many, and their titles, most
                // recently focused first.
                Tooltip {
                    target: slot
                    active: slot.toplevel !== null && root.openMenu === null

                    readonly property string name: Windows.appName(slot.toplevel)
                    readonly property string workspace: slot.toplevel?.workspace?.name ?? ""

                    image: slot.iconSource
                    title: slot.count > 1 ? name : Windows.shortTitle(slot.toplevel)
                    meta: slot.count > 1 ? slot.count + " windows" : ""
                    body: slot.count > 1
                        ? slot.app.windows.map(toplevel => Windows.shortTitle(toplevel)).join(" · ")
                        : workspace !== "" ? name + " · Workspace " + workspace : name
                }
            }
        }
    }
}
