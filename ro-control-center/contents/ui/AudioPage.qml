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

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        SliderRow {
            Layout.fillWidth: true
            iconName: root.backend && root.backend.muted ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"
            value: root.backend ? root.backend.volume : 0
            clickableIcon: true
            onMoved: v => {
                if (root.backend) {
                    root.backend.setVolume(v)
                }
            }
            onIconClicked: {
                if (root.backend) {
                    root.backend.setMuted(!root.backend.muted)
                }
            }
        }

        PC3.ToolButton {
            icon.name: root.backend && root.backend.muted ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"
            checked: root.backend ? root.backend.muted : false
            checkable: true
            onClicked: {
                if (root.backend) {
                    root.backend.setMuted(!root.backend.muted)
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: st.glassBorder
    }

    ListView {
        id: sinkList
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 160
        clip: true
        spacing: 4
        model: root.backend ? root.backend.sinkModel : null

        delegate: Rectangle {
            id: sinkRow
            width: sinkList.width
            height: 32
            radius: st.radiusItem

            readonly property bool isDefault: Boolean(model.PulseObject ? model.PulseObject.default : (model.Default ?? false))
            readonly property string sinkName: (model.PulseObject ? (model.PulseObject.description || model.PulseObject.name) : "") || (model.Description ?? model.Name ?? "")

            color: isDefault ? st.accentSoft : (sinkMouse.containsMouse ? st.hover : "transparent")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Kirigami.Icon {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    source: "audio-volume-high-symbolic"
                    isMask: true
                    color: Kirigami.Theme.textColor
                }

                PC3.Label {
                    Layout.fillWidth: true
                    text: sinkRow.sinkName
                    color: Kirigami.Theme.textColor
                    elide: Text.ElideRight
                }

                Kirigami.Icon {
                    visible: sinkRow.isDefault
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    source: "object-select-symbolic"
                    isMask: true
                    color: Kirigami.Theme.textColor
                }
            }

            MouseArea {
                id: sinkMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (model.PulseObject) {
                        model.PulseObject.default = true
                    }
                }
            }
        }
    }
}
