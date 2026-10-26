// ChipTabs.qml

import QtQuick
import QtQuick.Layouts

import qs.config

// A row of tabs: the current one is a chip with icon and label, the rest are
// round icon buttons. `placeholders` pads the row with empty circles for tabs
// that don't exist yet.
RowLayout {
    id: root

    property var tabs: [] // [{ icon, label }]
    property int current: 0
    property int placeholders: 0

    spacing: Theme.paddings

    Repeater {
        model: root.tabs

        delegate: Item {
            id: tab

            required property var modelData
            required property int index

            readonly property bool active: tab.index === root.current

            implicitWidth: tab.active ? chip.implicitWidth : button.implicitWidth
            implicitHeight: 28

            Rectangle {
                id: chip

                anchors.fill: parent
                visible: tab.active

                implicitWidth: chipRow.implicitWidth + Theme.paddings * 3
                radius: height / 2

                color: Theme.colors.container

                RowLayout {
                    id: chipRow

                    anchors.centerIn: parent
                    spacing: Theme.spacing

                    Text {
                        text: tab.modelData.icon
                        color: Theme.colors.fg

                        font.family: Theme.font.icons
                        font.pixelSize: Theme.font.medium
                    }

                    Text {
                        text: tab.modelData.label
                        color: Theme.colors.fg

                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.size
                    }
                }
            }

            IconButton {
                id: button

                anchors.centerIn: parent
                visible: !tab.active

                size: 28
                icon: tab.modelData.icon

                onClicked: root.current = tab.index
            }

            // Only the round buttons: the current tab already shows its label.
            Tooltip {
                target: button
                below: root
                active: !tab.active

                icon: tab.modelData.icon
                title: tab.modelData.label
            }
        }
    }

    Repeater {
        model: root.placeholders

        delegate: EmptySlot {
            size: 28
        }
    }
}
