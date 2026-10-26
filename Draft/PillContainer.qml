import QtQuick
import qs.config

Rectangle {
    id: root
    
    default property alias content: contentItem.data

    property real horizontalPadding: Theme.pHorizontal
    property real verticalPadding: Theme.pVertical

    implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + verticalPadding * 2

    property real leftPadding: horizontalPadding
    property real rightPadding: horizontalPadding
    property real topPadding: verticalPadding
    property real bottomPadding: verticalPadding

    radius: Theme.radius
    color: Theme.colors.surface

    Item {
        id: contentItem

        anchors {
            fill: parent
            leftMargin: root.leftPadding
            rightMargin: root.rightPadding
            topMargin: root.topPadding
            bottomMargin: root.bottomMargin
        }

        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
