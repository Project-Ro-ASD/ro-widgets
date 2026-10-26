/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.plasma.networkmanagement as PlasmaNM

ColumnLayout {
    id: root

    property var backend

    Style {
        id: st
    }

    spacing: 8

    RowLayout {
        Layout.fillWidth: true

        PC3.Label {
            Layout.fillWidth: true
            text: i18n("Wi-Fi")
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
            color: Kirigami.Theme.textColor
        }

        PC3.Switch {
            checked: root.backend ? root.backend.wifiEnabled : false
            onToggled: {
                if (root.backend) {
                    root.backend.setWifiEnabled(checked)
                }
            }
        }
    }

    PC3.Label {
        Layout.fillWidth: true
        text: root.backend && root.backend.wifiSsid !== ""
            ? i18n("Connected to %1", root.backend.wifiSsid)
            : i18n("Not connected")
        color: st.textMuted
        font.pointSize: st.fontSmall
        elide: Text.ElideRight
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: st.glassBorder
    }

    ListView {
        id: networkList
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 160
        clip: true
        spacing: 4
        model: root.backend ? root.backend.networkModel : null

        delegate: Rectangle {
            id: netRow
            width: networkList.width
            height: 32
            radius: st.radiusItem

            readonly property bool connected: (model.ConnectionState ?? -1) === PlasmaNM.Enums.Activated
            readonly property string netName: model.ItemUniqueName ?? model.Ssid ?? model.Name ?? ""

            color: connected ? st.accentSoft : (netMouse.containsMouse ? st.hover : "transparent")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Kirigami.Icon {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    source: model.ConnectionIcon ?? "network-wireless-symbolic"
                    isMask: true
                    color: Kirigami.Theme.textColor
                }

                PC3.Label {
                    Layout.fillWidth: true
                    text: netRow.netName
                    color: Kirigami.Theme.textColor
                    elide: Text.ElideRight
                }

                Kirigami.Icon {
                    visible: netRow.connected
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    source: "object-select-symbolic"
                    isMask: true
                    color: Kirigami.Theme.textColor
                }

                Kirigami.Icon {
                    visible: (model.SecurityType ?? 0) > 0
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    source: "object-locked-symbolic"
                    isMask: true
                    color: st.textMuted
                }
            }

            MouseArea {
                id: netMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (!root.backend) {
                        return
                    }
                    if (netRow.connected) {
                        root.backend.deactivateNetwork(model.ConnectionPath ?? "", model.DevicePath ?? "")
                    } else {
                        root.backend.activateNetwork(model.ConnectionPath ?? "", model.DevicePath ?? "", model.SpecificPath ?? "")
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PC3.Label {
            Layout.fillWidth: true
            text: i18n("Airplane mode")
            font.pointSize: st.fontSmall
            color: Kirigami.Theme.textColor
        }

        PC3.Switch {
            checked: root.backend ? root.backend.airplaneMode : false
            onToggled: {
                if (root.backend) {
                    root.backend.setAirplaneMode(checked)
                }
            }
        }
    }
}
