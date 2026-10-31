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

    property var backend

    Style {
        id: st
    }

    spacing: 8

    PC3.Label {
        Layout.fillWidth: true
        text: i18n("Keyboard Layout")
        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
        color: Kirigami.Theme.textColor
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: st.glassBorder
    }

    ListView {
        id: layoutList
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 120
        clip: true
        spacing: 4
        model: root.backend ? root.backend.keyboardLayouts : []

        delegate: Rectangle {
            id: layoutRow
            required property var modelData
            required property int index
            readonly property bool isCurrent: root.backend ? root.backend.currentLayout === index : false

            width: layoutList.width
            height: 34
            radius: st.radiusItem
            color: isCurrent ? st.accentSoft : (layoutMouse.containsMouse ? st.hover : "transparent")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                // Kısa ad rozeti (ör. "tr").
                Rectangle {
                    Layout.preferredWidth: badge.implicitWidth + 12
                    Layout.preferredHeight: 20
                    radius: st.radiusItem
                    color: layoutRow.isCurrent ? st.accent : st.glassRaised
                    border.width: layoutRow.isCurrent ? 0 : st.borderWidth
                    border.color: st.glassBorder

                    PC3.Label {
                        id: badge
                        anchors.centerIn: parent
                        text: layoutRow.modelData.shortName
                        font.pointSize: st.fontSmall
                        color: layoutRow.isCurrent ? st.onAccent : Kirigami.Theme.textColor
                    }
                }

                PC3.Label {
                    Layout.fillWidth: true
                    text: layoutRow.modelData.longName
                    color: Kirigami.Theme.textColor
                    elide: Text.ElideRight
                }

                Kirigami.Icon {
                    visible: layoutRow.isCurrent
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    source: "object-select-symbolic"
                    isMask: true
                    color: Kirigami.Theme.textColor
                }
            }

            MouseArea {
                id: layoutMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (root.backend) {
                        root.backend.setLayout(layoutRow.index)
                    }
                }
            }
        }
    }

    Rectangle {
        visible: root.backend ? root.backend.keyboardBrightnessAvailable : false
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: st.glassBorder
    }

    PC3.Label {
        visible: root.backend ? root.backend.keyboardBrightnessAvailable : false
        Layout.fillWidth: true
        text: i18nd("plasma_applet_org.kde.plasma.brightness", "Keyboard Backlight")
        font.pointSize: st.fontSmall
        color: st.textMuted
    }

    SliderRow {
        visible: root.backend ? root.backend.keyboardBrightnessAvailable : false
        Layout.fillWidth: true
        iconName: "input-keyboard-brightness"
        value: root.backend ? root.backend.keyboardBrightness : 0
        onMoved: v => {
            if (root.backend) {
                root.backend.setKeyboardBrightness(v)
            }
        }
    }
}
