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
import org.kde.coreaddons as KCoreAddons
import org.kde.kitemmodels as KItemModels

ColumnLayout {
    // Renk seti popup'tan açıkça kalıtılsın; yazılmayınca Style örnekleri Kirigami.Theme'i siyah okuyor (ro-launcher ile aynı sorun).
    Kirigami.Theme.inherit: true
    id: root

    property var backend
    property int _batteryRevision: 0

    Style {
        id: st
    }

    // KDE BatteryControlModel rolleri; dahili piller önce, cihaz pilleri sonra.
    readonly property var batteryRows: {
        _batteryRevision;
        const model = root.backend ? root.backend.batteriesModel : null;
        if (!model) {
            return [];
        }
        const names = ["PrettyName", "Percent", "Capacity", "Energy", "PluggedIn",
                       "IsPowerSupply", "ChargeState", "Type"];
        // KRoleNames modelin kendisine bağlanır (Backend.qml'deki kalıp).
        const ids = names.map(name => model.KItemModels.KRoleNames.role(name));
        const rows = [];
        for (let i = 0; i < model.rowCount(); ++i) {
            const idx = model.index(i, 0);
            rows.push({
                prettyName: model.data(idx, ids[0]) ?? "",
                percent: model.data(idx, ids[1]) ?? 0,
                capacity: model.data(idx, ids[2]) ?? 0,
                energy: model.data(idx, ids[3]) ?? 0,
                present: model.data(idx, ids[4]) ?? false,
                isPowerSupply: model.data(idx, ids[5]) ?? false,
                chargeState: model.data(idx, ids[6]) ?? 0,
                type: model.data(idx, ids[7]) ?? "",
            });
        }
        rows.sort((a, b) => (b.isPowerSupply ? 1 : 0) - (a.isPowerSupply ? 1 : 0));
        return rows;
    }

    readonly property var activeProfileHolds: {
        if (!root.backend || !root.backend.profileHolds) {
            return [];
        }
        return root.backend.profileHolds.filter(hold => hold.Profile === root.backend.activeProfile);
    }

    Connections {
        target: root.backend ? root.backend.batteriesModel : null
        function onDataChanged() { root._batteryRevision++; }
        function onModelReset() { root._batteryRevision++; }
        function onRowsInserted() { root._batteryRevision++; }
        function onRowsRemoved() { root._batteryRevision++; }
        function onRowsMoved() { root._batteryRevision++; }
    }

    // KDE BatteryIcon.qml'deki ad mantığı.
    function batteryIconName(row) {
        const typeIcons = {
            "Mouse": "input-mouse-battery",
            "Keyboard": "input-keyboard-battery",
            "Pda": "phone-battery",
            "Phone": "phone-battery",
            "Ups": "battery-ups",
            "GamingInput": "input-gaming-battery",
            "Bluetooth": "preferences-system-bluetooth-battery",
            "Headphone": "audio-headphones-battery",
            "Headset": "audio-headset-battery"
        };
        if (!row.present) {
            return "battery-missing";
        }
        if (typeIcons[row.type]) {
            return typeIcons[row.type];
        }
        let name;
        const p = row.percent;
        if (p >= 95) {
            name = "battery-100";
        } else if (p >= 85) {
            name = "battery-090";
        } else if (p >= 75) {
            name = "battery-080";
        } else if (p >= 65) {
            name = "battery-070";
        } else if (p >= 55) {
            name = "battery-060";
        } else if (p >= 45) {
            name = "battery-050";
        } else if (p >= 35) {
            name = "battery-040";
        } else if (p >= 25) {
            name = "battery-030";
        } else if (p >= 15) {
            name = "battery-020";
        } else if (p > 5) {
            name = "battery-010";
        } else {
            name = "battery-000";
        }
        // Şarj işareti yalnız güç kaynağı pillerde ve adaptör takılıyken.
        if (root.backend.pluggedIn && row.isPowerSupply) {
            name += "-charging";
        }
        return name;
    }

    function batteryStatusText(row) {
        if (!row.present) {
            return i18ndc("plasma_applet_org.kde.plasma.battery", "Battery is currently not present in the bay", "Not present");
        }
        switch (row.chargeState) {
        case 1:
            return i18nd("plasma_applet_org.kde.plasma.battery", "Charging");
        case 2:
            return i18nd("plasma_applet_org.kde.plasma.battery", "Discharging");
        case 3:
            return i18nd("plasma_applet_org.kde.plasma.battery", "Fully Charged");
        default:
            return i18nd("plasma_applet_org.kde.plasma.battery", "Not Charging");
        }
    }

    function profileLabel(profile) {
        if (profile === "power-saver") {
            return i18nd("plasma_applet_org.kde.plasma.battery", "Power Save");
        }
        if (profile === "performance") {
            return i18nd("plasma_applet_org.kde.plasma.battery", "Performance");
        }
        if (profile === "balanced") {
            return i18nd("plasma_applet_org.kde.plasma.battery", "Balanced");
        }
        return profile;
    }

    function profileInhibitionText() {
        switch (root.backend ? root.backend.profileInhibitionReason : "") {
        case "lap-detected":
            return i18nd("plasma_applet_org.kde.plasma.battery", "Performance mode has been disabled to reduce heat generation because the computer has detected that it may be sitting on your lap.");
        case "high-operating-temperature":
            return i18nd("plasma_applet_org.kde.plasma.battery", "Performance mode is unavailable because the computer is running too hot.");
        default:
            return i18nd("plasma_applet_org.kde.plasma.battery", "Performance mode is unavailable.");
        }
    }

    // KDE InhibitionItem.qml'deki cümleler.
    function inhibitionText(inh) {
        const why = inh.reason || i18ndc("plasma_applet_org.kde.plasma.battery", "An application's reason for inhibiting sleep and/or screen locking", "Unknown reason.");
        const isIdle = inh.behaviors.includes("idle");
        const isSleep = inh.behaviors.includes("sleep");
        if (!inh.allowed) {
            if (isIdle && isSleep) {
                return i18ndc("plasma_applet_org.kde.plasma.battery", "Application (1) with reason (2) has been prevented from blocking this inactivity behavior. The user can choose to allow it again.", "%1 wants to block sleep and screen locking. (%2)", inh.prettyName, why);
            } else if (isIdle) {
                return i18ndc("plasma_applet_org.kde.plasma.battery", "Application (1) with reason (2) has been prevented from blocking this inactivity behavior. The user can choose to allow it again.", "%1 wants to block screen locking. (%2)", inh.prettyName, why);
            } else if (isSleep) {
                return i18ndc("plasma_applet_org.kde.plasma.battery", "Application (1) with reason (2) has been prevented from blocking this inactivity behavior. The user can choose to allow it again.", "%1 wants to block sleep. (%2)", inh.prettyName, why);
            }
        } else if (inh.active && root.backend.manuallyInhibited) {
            if (isIdle && isSleep) {
                return i18ndc("plasma_applet_org.kde.plasma.battery", "Application (1) with reason (2) is currently blocking this inactivity behavior, in addition to the user's manual block switch.", "%1 is also blocking sleep and screen locking. (%2)", inh.prettyName, why);
            } else if (isIdle) {
                return i18ndc("plasma_applet_org.kde.plasma.battery", "Application (1) with reason (2) is currently blocking this inactivity behavior, in addition to the user's manual block switch.", "%1 is also blocking screen locking. (%2)", inh.prettyName, why);
            } else if (isSleep) {
                return i18ndc("plasma_applet_org.kde.plasma.battery", "Application (1) with reason (2) is currently blocking this inactivity behavior, in addition to the user's manual block switch.", "%1 is also blocking sleep. (%2)", inh.prettyName, why);
            }
        } else if (inh.active) {
            if (isIdle && isSleep) {
                return i18ndc("plasma_applet_org.kde.plasma.battery", "Application (1) with reason (2) is currently blocking this inactivity behavior, the user can choose to unblock it.", "%1 is blocking sleep and screen locking. (%2)", inh.prettyName, why);
            } else if (isIdle) {
                return i18ndc("plasma_applet_org.kde.plasma.battery", "Application (1) with reason (2) is currently blocking this inactivity behavior, the user can choose to unblock it.", "%1 is blocking screen locking. (%2)", inh.prettyName, why);
            } else if (isSleep) {
                return i18ndc("plasma_applet_org.kde.plasma.battery", "Application (1) with reason (2) is currently blocking this inactivity behavior, the user can choose to unblock it.", "%1 is blocking sleep. (%2)", inh.prettyName, why);
            }
        }
        return "";
    }

    spacing: 8

    RowLayout {
        Layout.fillWidth: true

        PC3.Label {
            Layout.fillWidth: true
            text: i18n("Power")
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
            color: Kirigami.Theme.textColor
        }

        // KDE batterymonitor main.qml'deki güç yönetimi ayarları.
        PC3.ToolButton {
            icon.name: "configure"
            visible: KConfig.KAuthorized.authorizeControlModule("kcm_powerdevilprofilesconfig")
            onClicked: {
                KCMUtils.KCMLauncher.openSystemSettings("kcm_powerdevilprofilesconfig");
                if (root.backend) {
                    root.backend.requestClose();
                }
            }

            PC3.ToolTip {
                text: i18nd("plasma_applet_org.kde.plasma.battery", "&Configure Power Management…")
            }
        }
    }

    PC3.Label {
        Layout.fillWidth: true
        text: i18nd("plasma_applet_org.kde.plasma.battery", "Power Profile")
        font.pointSize: st.fontSmall
        color: st.textMuted
    }

    PowerSelector {
        Layout.fillWidth: true
        backend: root.backend
    }

    // Profil engelliyse KDE'deki uyarı ve profili tutan uygulamalar.
    RowLayout {
        visible: root.backend ? root.backend.profileInhibitionReason !== "" : false
        Layout.fillWidth: true
        spacing: 6

        Kirigami.Icon {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            source: "dialog-information"
            isMask: true
            color: st.textMuted
        }

        PC3.Label {
            Layout.fillWidth: true
            text: root.profileInhibitionText()
            font.pointSize: st.fontSmall
            color: st.textMuted
            wrapMode: Text.WordWrap
        }
    }

    PC3.Label {
        visible: root.activeProfileHolds.length > 0
        Layout.fillWidth: true
        text: i18ndp("plasma_applet_org.kde.plasma.battery",
                     "One application has requested activating %2:",
                     "%1 applications have requested activating %2:",
                     root.activeProfileHolds.length,
                     root.profileLabel(root.backend ? root.backend.activeProfile : ""))
        font.pointSize: st.fontSmall
        color: st.textMuted
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: root.activeProfileHolds

        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 6

            Kirigami.Icon {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                source: modelData.Icon || "preferences-system"
                isMask: true
                color: st.textMuted
            }

            PC3.Label {
                Layout.fillWidth: true
                text: i18ndc("plasma_applet_org.kde.plasma.battery", "%1 is the name of the application, %2 is the reason provided by it for activating performance mode", "%1: %2", modelData.Name, modelData.Reason)
                font.pointSize: st.fontSmall
                color: st.textMuted
                wrapMode: Text.WordWrap
            }
        }
    }

    // --- Pil ---

    PC3.Label {
        visible: root.backend ? root.backend.hasBattery : false
        Layout.fillWidth: true
        text: i18nd("plasma_applet_org.kde.plasma.battery", "Power & Battery")
        font.pointSize: st.fontSmall
        color: st.textMuted
    }

    Rectangle {
        visible: root.backend ? root.backend.hasBattery : false
        Layout.fillWidth: true
        implicitHeight: batteryColumn.implicitHeight + 16
        radius: st.radiusCard
        color: st.glass
        border.width: st.borderWidth
        border.color: st.glassBorder

        ColumnLayout {
            id: batteryColumn
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            Repeater {
                model: root.batteryRows

                ColumnLayout {
                    id: batteryRow
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 2

                    readonly property bool isBroken: modelData.capacity > 0 && modelData.capacity < 50
                    readonly property bool detailsVisible: modelData.isPowerSupply
                    readonly property bool remainingVisible: modelData.isPowerSupply
                        && root.backend.remainingMsec > 0
                        && (modelData.chargeState === 1 || modelData.chargeState === 2)
                    readonly property bool estimating: modelData.isPowerSupply
                        && root.backend.remainingMsec === 0
                        && modelData.chargeState === 2
                    readonly property bool healthVisible: modelData.isPowerSupply
                        && modelData.capacity !== ""
                        && !batteryRow.isBroken

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Kirigami.Icon {
                            Layout.alignment: Qt.AlignTop
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            source: root.batteryIconName(batteryRow.modelData)
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                PC3.Label {
                                    Layout.fillWidth: true
                                    text: batteryRow.modelData.prettyName
                                    color: Kirigami.Theme.textColor
                                    elide: Text.ElideRight
                                }

                                PC3.Label {
                                    visible: batteryRow.modelData.isPowerSupply || batteryRow.modelData.chargeState !== 0
                                    text: root.batteryStatusText(batteryRow.modelData)
                                    font.pointSize: st.fontSmall
                                    color: st.textMuted
                                }

                                PC3.Label {
                                    visible: batteryRow.modelData.present
                                    text: i18ndc("plasma_applet_org.kde.plasma.battery", "Placeholder is battery percentage", "%1%", batteryRow.modelData.percent)
                                    font.pointSize: st.fontSmall
                                    color: Kirigami.Theme.textColor
                                }
                            }

                            PC3.ProgressBar {
                                visible: batteryRow.modelData.present
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: batteryRow.modelData.percent
                            }
                        }
                    }

                    GridLayout {
                        visible: batteryRow.detailsVisible
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 6
                        rowSpacing: 0

                        PC3.Label {
                            Layout.fillWidth: true
                            Layout.columnSpan: 2
                            visible: batteryRow.isBroken
                            text: i18nd("plasma_applet_org.kde.plasma.battery", "This battery's health is at only %1% and it should be replaced. Contact the manufacturer.", batteryRow.modelData.capacity)
                            font.pointSize: st.fontSmall
                            color: Kirigami.Theme.neutralTextColor
                            wrapMode: Text.WordWrap
                        }

                        PC3.Label {
                            Layout.fillWidth: true
                            visible: batteryRow.remainingVisible || batteryRow.estimating
                            text: batteryRow.modelData.chargeState === 1
                                ? i18nd("plasma_applet_org.kde.plasma.battery", "Time To Full:")
                                : i18nd("plasma_applet_org.kde.plasma.battery", "Remaining Time:")
                            font.pointSize: st.fontSmall
                            color: st.textMuted
                            wrapMode: Text.WordWrap
                        }

                        PC3.Label {
                            Layout.alignment: Qt.AlignRight
                            visible: batteryRow.remainingVisible || batteryRow.estimating
                            text: batteryRow.estimating
                                ? i18ndc("plasma_applet_org.kde.plasma.battery", "@info", "Estimating…")
                                : KCoreAddons.Format.formatDuration(root.backend.remainingMsec, KCoreAddons.FormatTypes.HideSeconds)
                            font.pointSize: st.fontSmall
                            color: st.textMuted
                        }

                        PC3.Label {
                            Layout.fillWidth: true
                            visible: batteryRow.healthVisible
                            text: i18nd("plasma_applet_org.kde.plasma.battery", "Battery Health:")
                            font.pointSize: st.fontSmall
                            color: st.textMuted
                        }

                        PC3.Label {
                            Layout.alignment: Qt.AlignRight
                            visible: batteryRow.healthVisible
                            text: i18ndc("plasma_applet_org.kde.plasma.battery", "Placeholder is battery health percentage", "%1%", batteryRow.modelData.capacity)
                            font.pointSize: st.fontSmall
                            color: st.textMuted
                        }

                        RowLayout {
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            visible: root.backend.pluggedIn
                                && batteryRow.modelData.isPowerSupply
                                && root.backend.chargeStopThreshold > 0
                                && root.backend.chargeStopThreshold < 100
                            spacing: 6

                            Kirigami.Icon {
                                Layout.preferredWidth: 12
                                Layout.preferredHeight: 12
                                source: "kt-speed-limits"
                                isMask: true
                                color: st.textMuted
                            }

                            PC3.Label {
                                Layout.fillWidth: true
                                text: i18nd("plasma_applet_org.kde.plasma.battery", "Battery is configured to charge up to approximately %1%.", root.backend.chargeStopThreshold)
                                font.pointSize: st.fontSmall
                                color: st.textMuted
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            // KDE batterymonitor: enerji bilgisi ayrı KCM'de açılır.
            PC3.Button {
                visible: KConfig.KAuthorized.authorizeControlModule("kcm_energyinfo")
                Layout.fillWidth: true
                icon.name: "documentinfo"
                text: i18nd("plasma_applet_org.kde.plasma.battery", "&Show Energy Information…")
                onClicked: {
                    KCMUtils.KCMLauncher.openInfoCenter("kcm_energyinfo");
                    if (root.backend) {
                        root.backend.requestClose();
                    }
                }
            }
        }
    }

    // --- Uyku engeli ---

    PC3.Label {
        Layout.fillWidth: true
        text: i18ndc("plasma_applet_org.kde.plasma.battery", "@title:group", "Sleep and Screen Locking after Inactivity")
        font.pointSize: st.fontSmall
        color: st.textMuted
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: inhibitionColumn.implicitHeight + 16
        radius: st.radiusCard
        color: st.glass
        border.width: st.borderWidth
        border.color: st.glassBorder

        ColumnLayout {
            id: inhibitionColumn
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            PC3.Switch {
                Layout.fillWidth: true
                text: i18ndc("plasma_applet_org.kde.plasma.battery", "@action:button Block sleep and screen locking after inactivity", "Manually Block Sleep and Screen Locking")
                checked: root.backend ? root.backend.manuallyInhibited : false
                onToggled: {
                    if (root.backend) {
                        root.backend.setManuallyInhibited(checked)
                    }
                }
            }

            RowLayout {
                visible: root.backend ? root.backend.manuallyInhibited : false
                Layout.fillWidth: true
                spacing: 6

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    source: "dialog-warning"
                    isMask: true
                    color: st.textMuted
                }

                PC3.Label {
                    Layout.fillWidth: true
                    text: i18ndc("plasma_applet_org.kde.plasma.battery", "@label corresponding to Manually Block Sleep and Screen Locking toggle", "This will result in higher energy consumption.")
                    font.pointSize: st.fontSmall
                    color: st.textMuted
                    wrapMode: Text.WordWrap
                }
            }

            RowLayout {
                visible: root.backend ? (root.backend.isLidPresent && !root.backend.triggersLidAction) : false
                Layout.fillWidth: true
                spacing: 6

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    source: "computer-laptop"
                    isMask: true
                    color: st.textMuted
                }

                PC3.Label {
                    Layout.fillWidth: true
                    text: i18ndc("plasma_applet_org.kde.plasma.battery", "Minimize the length of this string as much as possible", "Your laptop is configured not to sleep when closing the lid while an external monitor is connected.")
                    font.pointSize: st.fontSmall
                    color: st.textMuted
                    wrapMode: Text.WordWrap
                }
            }

            Repeater {
                model: root.backend ? root.backend.requestedInhibitions : []

                RowLayout {
                    id: inhibitionRow
                    required property var modelData

                    readonly property string rowText: root.inhibitionText(inhibitionRow.modelData)

                    Layout.fillWidth: true
                    spacing: 6
                    visible: inhibitionRow.rowText !== ""

                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: 12
                        Layout.preferredHeight: 12
                        source: inhibitionRow.modelData.icon || "system-suspend-inhibited"
                        isMask: true
                        color: st.textMuted
                    }

                    PC3.Label {
                        Layout.fillWidth: true
                        text: inhibitionRow.rowText
                        font.pointSize: st.fontSmall
                        color: st.textMuted
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
