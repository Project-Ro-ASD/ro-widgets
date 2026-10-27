/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

RowLayout {
    // Renk seti popup'tan açıkça kalıtılsın; yazılmayınca Style örnekleri Kirigami.Theme'i siyah okuyor (ro-launcher ile aynı sorun).
    Kirigami.Theme.inherit: true
    id: root

    property string iconName: ""
    property real value: 0
    property bool clickableIcon: false

    signal moved(real v)
    signal iconClicked()

    Style {
        id: st
    }

    spacing: 8

    Item {
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22

        Kirigami.Icon {
            anchors.centerIn: parent
            width: 18
            height: 18
            source: root.iconName
            isMask: true
            color: Kirigami.Theme.textColor
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.clickableIcon
            onClicked: root.iconClicked()
        }
    }

    PC3.Slider {
        id: slider
        Layout.fillWidth: true
        from: 0
        to: 1
        value: root.value
        onMoved: root.moved(value)
    }

    PC3.Label {
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value * 100) + "%"
        color: st.textMuted
    }
}
