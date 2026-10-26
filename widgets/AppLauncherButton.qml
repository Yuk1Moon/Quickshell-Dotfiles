// AppLauncherButton.qml

import QtQuick
import Quickshell.Io

import qs.widgets.appLauncher
import qs.components
import qs.config

PillContainer {
    id: root

    hoverable: true
    
    implicitWidth: 32
    implicitHeight: 32

    Text {
        anchors.centerIn: parent

        text: "\uf303"
        color: Theme.colors.fg

        font.family: Theme.font.family
        font.pixelSize: Theme.font.medium
    }

    MouseArea {
        id: cursor

        parent: root
        anchors.fill: parent
        z: 1

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: launcher.toggle()
    }

    AppLauncher {
        id: launcher
        anchorItem: root
    }

    // `qs ipc call launcher toggle` — bound to Super+R in Hyprland. Goes
    // through toggle(), which places the launcher before showing it.
    IpcHandler {
        target: "launcher"

        function toggle(): void { launcher.toggle() }
        function open(): void { if (!launcher.visible) launcher.toggle() }
        function close(): void { launcher.visible = false }
    }

    Tooltip {
        target: root
        active: !launcher.visible

        icon: "apps"
        title: "Applications"
        body: "Search and launch"
    }
}
