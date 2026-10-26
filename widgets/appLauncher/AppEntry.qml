// AppEntry.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.config

// One app in the launcher, as a card like the sidebar's: its icon in a round
// badge, its name, and what kind of app it is. `current` marks the one Enter
// would launch with the soft fill of a highlighted card and the ring a
// focused text field gets.
Control {
    id: root

    required property var app
    property bool current: false

    signal activated()

    // "Web Browser", "File Manager"; the comment when there's no generic
    // name, unless it only repeats the name (Obsidian's is "Obsidian").
    readonly property string detail: {
        const generic = root.app.genericName ?? ""
        if (generic !== "") return generic

        const comment = root.app.comment ?? ""
        return comment !== root.app.name ? comment : ""
    }

    hoverEnabled: true
    padding: Theme.paddings

    background: Rectangle {
        radius: Theme.radius
        color: Theme.colors.surface

        // Over the surface rather than instead of it: `container` alone is
        // mostly see-through, and the one card that matters most showed the
        // window behind.
        Rectangle {
            anchors.fill: parent
            radius: parent.radius

            color: Theme.colors.container
            opacity: root.current ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius

            color: Theme.colors.hover
            opacity: root.hovered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
        }

        // The fill alone barely showed against the other cards.
        Rectangle {
            anchors.fill: parent
            radius: parent.radius

            color: "transparent"
            border.width: 2
            border.color: Theme.colors.selected
            opacity: root.current ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
        }
    }

    contentItem: RowLayout {
        spacing: Theme.paddings

        // Icon badge
        Rectangle {
            implicitWidth: 36
            implicitHeight: 36
            radius: width / 2

            color: Theme.colors.hover

            IconImage {
                anchors.centerIn: parent

                implicitSize: 22
                source: Quickshell.iconPath(root.app.icon, "application-x-executable")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing / 2

            Text {
                Layout.fillWidth: true

                text: root.app.name
                elide: Text.ElideRight
                color: Theme.colors.fg

                font.family: Theme.font.family
                font.pixelSize: Theme.font.size
                font.weight: Font.Medium
            }

            Text {
                Layout.fillWidth: true
                visible: root.detail !== ""

                text: root.detail
                elide: Text.ElideRight
                color: Theme.colors.muted

                font.family: Theme.font.family
                font.pixelSize: Theme.font.small
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: root.activated()
    }
}
