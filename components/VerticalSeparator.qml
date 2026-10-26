// VerticalSeparator.qml

import QtQuick
import QtQuick.Layouts

import qs.config

Rectangle {
    property real referenceHeight: Theme.font.size

    color: Theme.colors.muted
    radius: width / 2

	Layout.preferredWidth: 1.2
    Layout.preferredHeight: referenceHeight * 0.75
    Layout.alignment: Qt.AlignVCenter
}