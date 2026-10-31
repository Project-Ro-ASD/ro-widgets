/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import org.kde.config as KConfig
import org.kde.plasma.networkmanagement as PlasmaNM

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

        PC3.Label {
            Layout.fillWidth: true
            text: i18n("Wi-Fi")
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
            color: Kirigami.Theme.textColor
        }

        // KDE Toolbar.qml'deki ağ ayarları düğmesi.
        PC3.ToolButton {
            icon.name: "configure"
            visible: KConfig.KAuthorized.authorizeControlModule("kcm_networkmanagement")
            onClicked: {
                KCMUtils.KCMLauncher.openSystemSettings("kcm_networkmanagement");
                if (root.backend) {
                    root.backend.requestClose();
                }
            }

            PC3.ToolTip {
                text: i18nd("plasma_applet_org.kde.plasma.networkmanagement", "Configure network connections…")
            }
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
            height: rowColumn.implicitHeight + 8
            radius: st.radiusItem

            readonly property bool connected: (model.ConnectionState ?? -1) === PlasmaNM.Enums.Activated
            readonly property bool activating: (model.ConnectionState ?? -1) === PlasmaNM.Enums.Activating
            readonly property string netName: model.ItemUniqueName ?? model.Ssid ?? model.Name ?? ""
            readonly property string connectionPath: model.ConnectionPath ?? ""
            readonly property string devicePath: model.DevicePath ?? ""
            readonly property string specificPath: model.SpecificPath ?? ""
            readonly property string uuid: model.Uuid ?? ""
            readonly property int securityType: model.SecurityType ?? 0
            // KDE ConnectionItem: kayıtsız, kablosuz ve statik şifreli ağlarda satır içi şifre sorulur.
            readonly property bool staticPassword: securityType === PlasmaNM.Enums.StaticWep
                || securityType === PlasmaNM.Enums.WpaPsk
                || securityType === PlasmaNM.Enums.Wpa2Psk
                || securityType === PlasmaNM.Enums.SAE
            readonly property bool predictableWirelessPassword: uuid === ""
                && (model.Type ?? -1) === PlasmaNM.Enums.Wireless
                && staticPassword

            property bool passwordPrompt: false

            color: connected ? st.accentSoft : (netMouse.containsMouse ? st.hover : "transparent")

            function submitPassword() {
                if (!root.backend || passwordField.text === "") {
                    return;
                }
                root.backend.activateNetwork("", netRow.devicePath, netRow.specificPath, passwordField.text);
                netRow.passwordPrompt = false;
            }

            ColumnLayout {
                id: rowColumn
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                spacing: 4

                RowLayout {
                    id: headerRow
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
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

                    PC3.BusyIndicator {
                        visible: netRow.activating
                        running: netRow.activating
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
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
                        visible: netRow.securityType > 0
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        source: "object-locked-symbolic"
                        isMask: true
                        color: st.textMuted
                    }

                    // Bağlı ağda bağlantıyı kes (KDE ConnectionItem).
                    PC3.ToolButton {
                        visible: netRow.connected
                        icon.name: "network-disconnect-symbolic"
                        onClicked: {
                            if (root.backend) {
                                root.backend.deactivateNetwork(netRow.connectionPath, netRow.devicePath);
                            }
                        }

                        PC3.ToolTip {
                            text: i18nd("plasma_applet_org.kde.plasma.networkmanagement", "Disconnect")
                        }
                    }

                    // Kayıtlı ağın ayarı, Uuid ile açılır (KDE ConnectionItem).
                    PC3.ToolButton {
                        visible: netRow.uuid !== ""
                        icon.name: "configure"
                        onClicked: {
                            KCMUtils.KCMLauncher.openSystemSettings("kcm_networkmanagement", ["--args", "Uuid=" + netRow.uuid]);
                            if (root.backend) {
                                root.backend.requestClose();
                            }
                        }

                        PC3.ToolTip {
                            text: i18nd("plasma_applet_org.kde.plasma.networkmanagement", "Configure…")
                        }
                    }
                }

                // KDE PasswordField: göster/gizle düğmesi Kirigami alanında hazır.
                RowLayout {
                    visible: netRow.passwordPrompt
                    Layout.fillWidth: true
                    spacing: 4

                    Kirigami.PasswordField {
                        id: passwordField
                        Layout.fillWidth: true
                        placeholderText: i18nd("plasma_applet_org.kde.plasma.networkmanagement", "Password…")
                        onAccepted: netRow.submitPassword()

                        validator: RegularExpressionValidator {
                            regularExpression: (netRow.securityType === PlasmaNM.Enums.StaticWep)
                                ? /^(?:.{5}|[0-9a-fA-F]{10}|.{13}|[0-9a-fA-F]{26})$/
                                : /^(?:.{8,64})$/
                        }
                    }

                    PC3.Button {
                        text: i18nd("plasma_applet_org.kde.plasma.networkmanagement", "Connect")
                        enabled: passwordField.acceptableInput
                        onClicked: netRow.submitPassword()
                    }
                }
            }

            // Ana satır tıklaması; şifre alanının üstünü kapatmaz.
            MouseArea {
                id: netMouse
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 32
                hoverEnabled: true
                z: -1
                onClicked: {
                    if (!root.backend) {
                        return;
                    }
                    if (netRow.connected) {
                        root.backend.deactivateNetwork(netRow.connectionPath, netRow.devicePath);
                    } else if (netRow.predictableWirelessPassword) {
                        netRow.passwordPrompt = true;
                        passwordField.forceActiveFocus();
                    } else {
                        root.backend.activateNetwork(netRow.connectionPath, netRow.devicePath, netRow.specificPath);
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
