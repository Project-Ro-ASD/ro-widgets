/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.bluetooth as PlasmaBt

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
            text: i18n("Bluetooth")
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
            color: Kirigami.Theme.textColor
        }

        PC3.Switch {
            enabled: root.backend ? root.backend.bluetoothAvailable : false
            checked: root.backend ? root.backend.bluetoothEnabled : false
            onToggled: {
                if (root.backend) {
                    root.backend.setBluetoothEnabled(checked)
                }
            }
        }
    }

    PC3.Label {
        visible: !(root.backend && root.backend.bluetoothAvailable)
        Layout.fillWidth: true
        text: i18n("No Bluetooth adapter")
        color: st.textMuted
        font.pointSize: st.fontSmall
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: st.glassBorder
    }

    ListView {
        id: btList
        visible: Boolean(root.backend && root.backend.bluetoothAvailable)
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 160
        clip: true
        spacing: 4
        model: (root.backend && root.backend.bluetoothAvailable && root.backend.bluetoothEnabled)
            ? root.backend.bluetoothDevicesModel
            : null

        delegate: Rectangle {
            id: devRow
            width: btList.width
            height: 32
            radius: st.radiusItem

            readonly property bool connected: Boolean(model.Connected)
            readonly property string devName: model.DeviceFullName ?? model.Name ?? ""

            color: connected ? st.accentSoft : (devMouse.containsMouse ? st.hover : "transparent")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Kirigami.Icon {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    source: (model.Icon ?? "preferences-system-bluetooth") + "-symbolic"
                    isMask: true
                    color: Kirigami.Theme.textColor
                }

                PC3.Label {
                    Layout.fillWidth: true
                    text: devRow.devName
                    color: Kirigami.Theme.textColor
                    elide: Text.ElideRight
                }

                PC3.Label {
                    text: devRow.connected ? i18n("Connected") : i18n("Not connected")
                    color: st.textMuted
                    font.pointSize: st.fontSmall
                }
            }

            MouseArea {
                id: devMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (model.Connecting || model.Disconnecting || !model.Device) {
                        return
                    }
                    if (model.Connected) {
                        const call = model.Device.disconnectFromDevice()
                        if (model.Ubi) {
                            PlasmaBt.SharedDevicesStateProxyModel.registerDisconnectingCallForDeviceUbi(call, model.Ubi)
                        }
                    } else {
                        const call = model.Device.connectToDevice()
                        if (model.Ubi) {
                            PlasmaBt.SharedDevicesStateProxyModel.registerConnectingCallForDeviceUbi(call, model.Ubi)
                        }
                    }
                }
            }
        }
    }
}
