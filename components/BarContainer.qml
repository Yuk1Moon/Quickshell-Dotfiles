// BarContainer.qml

import QtQuick
import QtQuick.Controls

import qs.config

Control {
    id: root

    implicitHeight: Settings.bar.height

    default property alias content: container.data

    leftPadding: Theme.pHorizontal
    rightPadding: Theme.pHorizontal
    topPadding: Theme.pVertical
    bottomPadding: Theme.pVertical

    // No implicitWidth from childrenRect: the sections anchor to the
    // container's edges, so measuring them fed the width back into itself.
    // The bar always fills its PanelWindow anyway.
    contentItem: Item {
        id: container

        implicitHeight: childrenRect.height
    }

    background: Rectangle {
        color: Theme.colors.bg
        radius: Theme.edges        
    }    
}