// PillContainer.qml

import QtQuick
import QtQuick.Controls

import qs.config

Control {
    id: root

    property bool hoverable: false

    implicitHeight: 32
    hoverEnabled: hoverable

    default property alias content: container.data

    leftPadding: Theme.pHorizontal
    rightPadding: Theme.pHorizontal
    topPadding: Theme.pVertical
    bottomPadding: Theme.pVertical

    contentItem: Item {
        id: container
        
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }

    background: Rectangle {
        color: Theme.colors.surface
        radius: Theme.radius

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.colors.hover
            opacity: root.hoverable && root.hovered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
        }
    }
}
