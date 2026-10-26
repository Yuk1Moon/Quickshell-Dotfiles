// PopupContainer.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

import qs.config

Control {
    id: root

    property real radius: Theme.radius
    property color surface: Theme.colors.surface
    property color tint: "transparent" // Laid over the surface, inside the border

    default property alias content: container.data

    padding: Theme.paddings

    contentItem: Item {
        id: container

        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }

    background: Item {
        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.border
            radius: Math.max(0, root.radius - Theme.border)
            color: root.surface
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.border
            radius: Math.max(0, root.radius - Theme.border)
            color: root.tint
        }

        Shape {
            id: borderShape
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill

                fillGradient: LinearGradient {
                    // True 45deg diagonal (top-left -> bottom-right), like
                    // Hyprland's border gradient — independent of aspect ratio.
                    readonly property real offset: (borderShape.width + borderShape.height) / 4

                    x1: borderShape.width / 2 - offset
                    y1: borderShape.height / 2 - offset
                    x2: borderShape.width / 2 + offset
                    y2: borderShape.height / 2 + offset

                    GradientStop { position: 0.0; color: Theme.gradient.top }
                    GradientStop { position: 0.5; color: Theme.gradient.mid }
                    GradientStop { position: 1.0; color: Theme.gradient.bottom }
                }

                // Outer contour and inner hole form the border.
                PathRectangle {
                    x: 0
                    y: 0
                    width: borderShape.width
                    height: borderShape.height
                    radius: root.radius
                }

                PathRectangle {
                    x: Theme.border
                    y: Theme.border
                    width: Math.max(0, borderShape.width - 2 * Theme.border)
                    height: Math.max(0, borderShape.height - 2 * Theme.border)
                    radius: Math.max(0, root.radius - Theme.border)
                }
            }
        }
    }
}
