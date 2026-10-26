// RingIndicator.qml

import QtQuick
import QtQuick.Shapes

import qs.config

Shape {
    id: root

    property real progress: 0 // 0.0 - 1.0
    property color color: Theme.colors.fg
    property color trackColor: Theme.colors.muted
    property real thickness: 2

    implicitWidth: 16
    implicitHeight: 16

    preferredRendererType: Shape.CurveRenderer
    antialiasing: true

    readonly property real ringRadius: Math.min(width, height) / 2 - thickness / 2

    // Track
    ShapePath {
        fillColor: "transparent"
        strokeColor: Qt.alpha(root.trackColor, 0.35)
        strokeWidth: root.thickness
        capStyle: ShapePath.RoundCap

        PathAngleArc {
            centerX: root.width / 2
            centerY: root.height / 2
            radiusX: root.ringRadius
            radiusY: root.ringRadius
            startAngle: -90
            sweepAngle: 360
        }
    }

    // Progress
    ShapePath {
        fillColor: "transparent"
        strokeColor: root.color
        strokeWidth: root.thickness
        capStyle: ShapePath.RoundCap

        PathAngleArc {
            centerX: root.width / 2
            centerY: root.height / 2
            radiusX: root.ringRadius
            radiusY: root.ringRadius
            startAngle: -90
            sweepAngle: 360 * Math.min(1, root.progress)

            Behavior on sweepAngle {
                NumberAnimation { duration: 150 }
            }
        }
    }
}
