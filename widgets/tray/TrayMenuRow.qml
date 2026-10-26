// TrayMenuRow.qml

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.config

// One row of a tray menu, drawn like the power menu's: a leading symbol or
// icon, the label, and a trailing symbol (the arrow into a submenu). Dims
// itself and ignores the pointer when disabled.
Rectangle {
    id: root

    property string symbol // Material symbol before the label
    property string image // An icon path instead
    property bool lead: root.symbol !== "" || root.image !== "" // Keep the leading column, so labels line up
    property string text
    property bool emphasized: false // Medium weight, e.g. the submenu's title
    property string trailing // Material symbol after the label

    signal clicked()

    implicitWidth: row.implicitWidth + Theme.paddings * 2
    implicitHeight: 36
    radius: Theme.radius

    opacity: root.enabled ? 1 : 0.4
    color: cursor.containsMouse ? Theme.colors.hover : "transparent"

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: Theme.paddings
        anchors.rightMargin: Theme.paddings

        spacing: Theme.paddings

        Item {
            visible: root.lead

            implicitWidth: Theme.font.medium
            implicitHeight: Theme.font.medium

            Text {
                anchors.centerIn: parent
                visible: root.image === ""

                text: root.symbol
                color: Theme.colors.fg

                font.family: Theme.font.icons
                font.pixelSize: Theme.font.medium
            }

            IconImage {
                anchors.centerIn: parent
                visible: root.image !== ""

                implicitSize: Theme.font.medium
                source: root.image
            }
        }

        Text {
            Layout.fillWidth: true

            text: root.text
            elide: Text.ElideRight
            color: Theme.colors.fg

            font.family: Theme.font.family
            font.pixelSize: Theme.font.size
            font.weight: root.emphasized ? Font.Medium : Font.Normal
        }

        Text {
            visible: root.trailing !== ""

            text: root.trailing
            color: Theme.colors.muted

            font.family: Theme.font.icons
            font.pixelSize: Theme.font.medium
        }
    }

    MouseArea {
        id: cursor

        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
    }
}
