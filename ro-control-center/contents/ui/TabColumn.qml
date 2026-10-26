/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

ColumnLayout {
    // Renk seti popup'tan açıkça kalıtılsın; yazılmayınca Style örnekleri Kirigami.Theme'i siyah okuyor (ro-launcher ile aynı sorun).
    Kirigami.Theme.inherit: true
    id: root

    property var tabs: []
    property string current: ""

    signal selected(string id)

    Style {
        id: st
    }

    spacing: 6

    Repeater {
        model: root.tabs

        delegate: Rectangle {
            id: tabItem
            required property var modelData
            readonly property bool isCurrent: root.current === modelData.id

            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            Layout.alignment: Qt.AlignHCenter
            radius: st.radiusCard
            color: isCurrent ? st.accent : (tabMouse.containsMouse ? st.hover : "transparent")

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 20
                height: 20
                source: tabItem.modelData.icon ?? ""
                isMask: true
                color: tabItem.isCurrent ? st.onAccent : Kirigami.Theme.textColor
            }

            MouseArea {
                id: tabMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.selected(tabItem.modelData.id)
            }

            PC3.ToolTip.text: tabItem.modelData.label ?? ""
            PC3.ToolTip.visible: tabMouse.containsMouse && Boolean(tabItem.modelData.label)
            PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }
}
