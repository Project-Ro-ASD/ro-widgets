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

ColumnLayout {
    // Renk seti popup'tan açıkça kalıtılsın; yazılmayınca Style örnekleri Kirigami.Theme'i siyah okuyor (ro-launcher ile aynı sorun).
    Kirigami.Theme.inherit: true
    id: root

    property var backend

    Style {
        id: st
    }

    spacing: 12

    RowLayout {
        Layout.fillWidth: true

        PC3.Label {
            Layout.fillWidth: true
            text: i18n("Display")
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
            color: Kirigami.Theme.textColor
        }

        // Parlaklık ekran ayarlarına bağlanır.
        PC3.ToolButton {
            icon.name: "configure"
            visible: KConfig.KAuthorized.authorizeControlModule("kcm_kscreen")
            onClicked: {
                KCMUtils.KCMLauncher.openSystemSettings("kcm_kscreen");
                if (root.backend) {
                    root.backend.requestClose();
                }
            }

            PC3.ToolTip {
                text: i18ndc("plasma_applet_org.kde.plasma.brightness", "@action:button", "Configure…")
            }
        }
    }

    SliderRow {
        visible: root.backend ? root.backend.brightnessAvailable : false
        Layout.fillWidth: true
        iconName: "display-brightness-symbolic"
        value: root.backend ? root.backend.brightness : 0
        onMoved: v => {
            if (root.backend) {
                root.backend.setBrightness(v)
            }
        }
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

    // Vurgu rengini izleme anahtarı (KDE KeyboardColorItem).
    RowLayout {
        visible: root.backend ? root.backend.keyboardColorAvailable : false
        Layout.fillWidth: true

        Kirigami.Icon {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            source: "input-keyboard-color"
            isMask: true
            color: Kirigami.Theme.textColor
        }

        PC3.Label {
            Layout.fillWidth: true
            text: i18nd("plasma_applet_org.kde.plasma.brightness", "Follow accent color")
            color: Kirigami.Theme.textColor
        }

        PC3.Switch {
            checked: root.backend ? root.backend.keyboardColorFollowsAccent : false
            onToggled: {
                if (root.backend) {
                    root.backend.setKeyboardColorFollowsAccent(checked)
                }
            }
        }
    }

    RowLayout {
        visible: root.backend ? root.backend.nightLightAvailable : true
        Layout.fillWidth: true

        Kirigami.Icon {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            source: "night-light-symbolic"
            isMask: true
            color: Kirigami.Theme.textColor
        }

        PC3.Label {
            Layout.fillWidth: true
            text: i18n("Night Light")
            color: Kirigami.Theme.textColor
        }

        PC3.Switch {
            enabled: root.backend ? root.backend.nightLightAvailable : false
            checked: root.backend ? root.backend.nightLightActive : false
            onToggled: {
                if (root.backend) {
                    root.backend.toggleNightLight()
                }
            }
        }

        PC3.ToolButton {
            icon.name: "configure"
            visible: KConfig.KAuthorized.authorizeControlModule("kcm_nightlight")
            onClicked: {
                KCMUtils.KCMLauncher.openSystemSettings("kcm_nightlight");
                if (root.backend) {
                    root.backend.requestClose();
                }
            }

            PC3.ToolTip {
                text: i18ndc("plasma_applet_org.kde.plasma.brightness", "@action:inmenu", "Configure Night Light…")
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Kirigami.Icon {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            source: "weather-clear-night-symbolic"
            isMask: true
            color: Kirigami.Theme.textColor
        }

        PC3.Label {
            Layout.fillWidth: true
            text: i18n("Dark Theme")
            color: Kirigami.Theme.textColor
        }

        PC3.Switch {
            checked: root.backend ? root.backend.darkMode : false
            onToggled: {
                if (root.backend) {
                    root.backend.setDarkMode(checked)
                }
            }
        }

        PC3.ToolButton {
            icon.name: "configure"
            visible: KConfig.KAuthorized.authorizeControlModule("kcm_landingpage")
            onClicked: {
                KCMUtils.KCMLauncher.openSystemSettings("kcm_landingpage");
                if (root.backend) {
                    root.backend.requestClose();
                }
            }

            PC3.ToolTip {
                text: i18nd("plasma_applet_org.kde.plasma.brightness", "Configure…")
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
