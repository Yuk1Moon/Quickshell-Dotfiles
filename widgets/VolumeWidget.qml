// VolumeWidget.qml

import QtQuick
import QtQuick.Layouts

import qs.config
import qs.services
import qs.components

PillContainer {
    id: root

    hoverable: true

    RowLayout {
        anchors.verticalCenter: parent.verticalCenter

        spacing: Theme.spacing

        // Status Color
        readonly property color statusColor: Audio.muted
            ? Theme.colors.error
            : Theme.colors.fg

        // Level ring
        RingIndicator {
            Layout.alignment: Qt.AlignVCenter

            implicitWidth: 16
            implicitHeight: 16

            progress: Audio.volume
            color: parent.statusColor
        }

        // Muted: a crossed-out speaker in place of the percentage.
        Text {
            visible: Audio.muted

            text: "volume_off"
            color: parent.statusColor

            font.family: Theme.font.icons
            font.pixelSize: Theme.font.medium
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: !Audio.muted

            text: Math.round(Audio.volume * 100) + "%"
            color: parent.statusColor

            font.family: Theme.font.family
            font.pixelSize: Theme.font.size
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        parent: root
        anchors.fill: parent
        z: 1

        cursorShape: Qt.PointingHandCursor

        onClicked: Audio.toggleMute()

        onWheel: (wheel) => {
            const step = Settings.audio.step / 100
            const delta = wheel.angleDelta.y > 0 ? step : -step
            Audio.setVolume(Audio.volume + delta)
        }
    }

    Tooltip {
        target: root

        icon: Audio.muted ? "volume_off"
            : Audio.volume < 0.5 ? "volume_down"
            : "volume_up"

        title: "Volume"
        meta: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
        body: Audio.device
        progress: Audio.volume
        progressColor: Audio.muted ? Theme.colors.muted : Theme.colors.accent
    }
}
