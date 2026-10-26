// BrightnessWidget.qml

import QtQuick
import QtQuick.Layouts

import qs.config
import qs.services
import qs.components

PillContainer {
    id: root

    hoverable: true

    // Hide the whole pill where there's no backlight (a desktop, or a wrong
    // device name in Settings) instead of leaving an empty one in the bar.
    visible: Brightness.ready

    RowLayout {
        anchors.verticalCenter: parent.verticalCenter

        spacing: Theme.spacing

        // Level ring
        RingIndicator {
            Layout.alignment: Qt.AlignVCenter

            implicitWidth: 16
            implicitHeight: 16

            progress: Brightness.level
            color: Theme.colors.fg
        }

        Text {
            text: Math.round(Brightness.percent) + "%"
            color: Theme.colors.fg

            font.family: Theme.font.family
            font.pixelSize: Theme.font.size
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Scroll only. Brightness has no toggle equivalent to mute, so there's no
    // onClicked and the cursor stays an arrow rather than promising one.
    // The step lives in the service (Settings.brightness.step) via
    // increase()/decrease(), not inline here.
    MouseArea {
        parent: root
        anchors.fill: parent
        z: 1

        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                Brightness.increase()
            } else {
                Brightness.decrease()
            }
        }
    }

    Tooltip {
        target: root

        icon: Brightness.dimmed ? "brightness_low" : "brightness_6"
        title: "Brightness"
        meta: Math.round(Brightness.percent) + "%"
        progress: Brightness.level
    }
}
