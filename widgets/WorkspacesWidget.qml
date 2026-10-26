// WorkspacesWidget.qml

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

import qs.components
import qs.config
import qs.services

PillContainer {
    RowLayout {
        spacing: Theme.spacing
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: Hyprland.workspaces

            delegate: Rectangle {
                id: workspace

                required property var modelData
                visible: Number(modelData.id) >= 0
                
                implicitWidth: 24
                implicitHeight: 24
                radius: Theme.edges

                color: modelData.active
                    ? Theme.colors.fg
                    : cursor.containsMouse
                        ? Theme.colors.hover : "transparent"

    
                Text {
                    id: label

                    anchors.centerIn: parent
                    text: modelData.id

                    color: modelData.active
                        ? Theme.colors.bg : Theme.colors.fg 
                }

                MouseArea {
                    id: cursor
                    
                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: modelData.activate()
                }

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                Tooltip {
                    target: workspace

                    readonly property var windows: workspace.modelData.toplevels.values

                    // Each app once, in the order Hyprland lists the windows.
                    readonly property var apps: [...new Set(
                        windows.map(toplevel => Windows.appName(toplevel)).filter(name => name !== "")
                    )]

                    icon: "workspaces"
                    title: "Workspace " + workspace.modelData.name
                    body: windows.length === 0 ? "Empty"
                        : (windows.length === 1 ? "1 window" : windows.length + " windows")
                            + " · " + apps.join(", ")
                }
            }
        }
    }
}