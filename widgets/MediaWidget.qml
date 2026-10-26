// MediaWidget.qml

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.config
import qs.services
import qs.components

// What's playing: the cover, the title and artist, and previous / play-pause
// / next. Hidden while no player is open. Muted text while paused.
PillContainer {
    id: root

    visible: Media.available

    RowLayout {
        anchors.verticalCenter: parent.verticalCenter

        spacing: Theme.spacing

        // Cover and title: what the tooltip hangs from.
        RowLayout {
            id: track

            spacing: Theme.spacing + 2

            // The cover in a small rounded square; a note while there's none
            // or it doesn't load.
            ClippingRectangle {
                Layout.alignment: Qt.AlignVCenter

                implicitWidth: 20
                implicitHeight: 20
                radius: Theme.edges / 2

                color: Theme.colors.hover

                Image {
                    id: cover

                    anchors.fill: parent

                    source: Media.artUrl
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 40
                    sourceSize.height: 40
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready

                    text: "music_note"
                    color: Theme.colors.fg

                    font.family: Theme.font.icons
                    font.pixelSize: Theme.font.size
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: Settings.media.maxWidth

                text: Media.artist !== "" ? Media.title + " · " + Media.artist : Media.title
                elide: Text.ElideRight
                color: Media.isPlaying ? Theme.colors.fg : Theme.colors.muted

                font.family: Theme.font.family
                font.pixelSize: Theme.font.size

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }
            }
        }

        IconButton {
            Layout.alignment: Qt.AlignVCenter
            enabled: Media.canPrevious

            size: 20
            iconSize: Theme.font.medium
            icon: "skip_previous"

            onClicked: Media.previous()
        }

        IconButton {
            Layout.alignment: Qt.AlignVCenter
            enabled: Media.canPlayPause

            size: 20
            iconSize: Theme.font.medium
            icon: Media.isPlaying ? "pause" : "play_arrow"

            onClicked: Media.playPause()
        }

        IconButton {
            Layout.alignment: Qt.AlignVCenter
            enabled: Media.canNext

            size: 20
            iconSize: Theme.font.medium
            icon: "skip_next"

            onClicked: Media.next()
        }
    }

    // Title, time and artist / album, with how far along it is.
    Tooltip {
        target: track

        icon: Media.isPlaying ? "play_arrow" : "pause"
        picture: Media.artUrl

        title: Media.title
        meta: Media.length > 0 ? Media.time(Media.position) + " / " + Media.time(Media.length) : ""
        body: [Media.artist, Media.album].filter(text => text !== "").join(" · ") || Media.app
        progress: Media.length > 0 ? Media.position / Media.length : -1
    }
}
