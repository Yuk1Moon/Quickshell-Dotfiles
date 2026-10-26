// InfoCard.qml

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.config

// The card tooltips and the OSD share, drawn like a notification toast: the
// gradient-bordered popup, a round badge, a title with a muted value where a
// notification has its time, a muted line of detail underneath, and an
// optional level bar. Fades in while dropping a few pixels into place.
PopupContainer {
    id: root

    property bool shown: true

    property string icon // Material symbol in the badge
    property string image // An icon path instead, e.g. an app's icon
    property string picture // A picture filling the badge, e.g. an album cover; over the rest once loaded
    property bool alert: false // Accent badge and tint, like a critical notification

    property string title
    property string meta // Muted, right of the title
    property string body // Muted, under the title; up to two lines

    property real progress: -1 // 0.0 - 1.0 draws a level bar; -1 for none
    property color progressColor: Theme.colors.accent

    // What the content needs, padding included, for the window around the
    // card to size itself by. Not implicitWidth/Height: PopupContainer takes
    // those from childrenRect, which follows the width the card is given, so
    // a window sized by them would feed its own width back in.
    readonly property real naturalWidth: content.implicitWidth + root.leftPadding + root.rightPadding
    readonly property real naturalHeight: content.implicitHeight + root.topPadding + root.bottomPadding

    radius: Theme.radiusCard
    tint: root.alert ? Theme.colors.container : "transparent"

    // Nearly opaque, unlike the toasts: these land on top of whatever window
    // is there, and with the usual see-through surface that window's text
    // read right through the card's.
    surface: Qt.alpha(Theme.colors.surface, 0.95)

    opacity: root.shown ? 1 : 0

    transform: Translate {
        y: root.shown ? 0 : -Theme.spacing

        Behavior on y {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    RowLayout {
        id: content

        width: parent.width
        spacing: Theme.paddings

        // Badge
        Rectangle {
            Layout.alignment: Qt.AlignVCenter

            implicitWidth: 32
            implicitHeight: 32
            radius: width / 2

            color: root.alert ? Theme.colors.accent : Theme.colors.hover

            IconImage {
                anchors.centerIn: parent
                visible: root.image !== ""

                implicitSize: 18
                source: root.image
            }

            // Over the icon or symbol, which show until it loads or if it fails.
            ClippingRectangle {
                anchors.fill: parent
                z: 1
                visible: cover.status === Image.Ready

                radius: width / 2
                color: "transparent"

                Image {
                    id: cover

                    anchors.fill: parent

                    source: root.picture
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2
                    asynchronous: true
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.image === ""

                text: root.icon
                color: root.alert ? Theme.colors.onAccent : Theme.colors.fg

                font.family: Theme.font.icons
                font.pixelSize: Theme.font.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            spacing: Theme.spacing / 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.paddings + Theme.spacing

                Text {
                    Layout.fillWidth: true

                    text: root.title
                    elide: Text.ElideRight
                    color: Theme.colors.fg

                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.size
                    font.weight: Font.Medium
                }

                Text {
                    visible: root.meta !== ""

                    text: root.meta
                    color: Theme.colors.muted

                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.small
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.body !== ""

                text: root.body
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Theme.colors.muted

                font.family: Theme.font.family
                font.pixelSize: Theme.font.small
            }

            // Level bar
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacing
                visible: root.progress >= 0

                implicitHeight: 4
                radius: height / 2

                color: Theme.colors.hover

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.progress))
                    height: parent.height
                    radius: parent.radius

                    color: root.progressColor

                    Behavior on width {
                        NumberAnimation { duration: 120 }
                    }
                }
            }
        }
    }
}
