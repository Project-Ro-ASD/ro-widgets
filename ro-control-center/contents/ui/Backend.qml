/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.kitemmodels as KItemModels

import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.bluezqt as BluezQt
import org.kde.plasma.private.bluetooth as PlasmaBt
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.private.brightnesscontrolplugin
import org.kde.plasma.workspace.dbus as DBus
import org.kde.plasma.private.batterymonitor
import org.kde.plasma.private.battery
import org.kde.plasma.private.volume

// KDE'nin kendi QML arka uç türleri tek yerde toplanır. Singleton'lar örneklenmez:
// DarkModeControl, NightLightInhibitor, BluezQt.Manager, NotificationManager.Server,
// PulseAudio, PreferredDevice. Cihaz yoksa ilgili ...Available / has... false olur.
Item {
    id: backend
    visible: false

    // --- Wi-Fi ---

    PlasmaNM.EnabledConnections { id: enabledConnections }
    PlasmaNM.AvailableDevices { id: availableDevices }
    PlasmaNM.Handler { id: handler }
    PlasmaNM.NetworkModel { id: connectionModel }
    PlasmaNM.AppletProxyModel {
        id: appletProxyModel
        sourceModel: connectionModel
    }

    // KDE applet'inin arayüzdeki filtreli/sıralı proxy modeli.
    property alias networkModel: appletProxyModel

    readonly property bool wifiEnabled: enabledConnections.wirelessEnabled

    // Model değişince SSID bağlaması yeniden hesaplansın diye sayaç.
    property int _networkRevision: 0

    Connections {
        target: appletProxyModel
        function onDataChanged() { backend._networkRevision++; }
        function onModelReset() { backend._networkRevision++; }
        function onRowsInserted() { backend._networkRevision++; }
        function onRowsRemoved() { backend._networkRevision++; }
    }

    // Bağlı Wi-Fi satırının SSID'si; ayrı bir özellik yok, modelden okunur.
    readonly property string wifiSsid: {
        _networkRevision;
        if (!enabledConnections.wirelessEnabled) {
            return "";
        }
        const count = appletProxyModel.rowCount();
        for (var i = 0; i < count; i++) {
            const index = appletProxyModel.index(i, 0);
            if (appletProxyModel.data(index, PlasmaNM.NetworkModel.ConnectionStateRole) !== PlasmaNM.Enums.Activated) {
                continue;
            }
            if (appletProxyModel.data(index, PlasmaNM.NetworkModel.TypeRole) !== PlasmaNM.Enums.Wireless) {
                continue;
            }
            return appletProxyModel.data(index, PlasmaNM.NetworkModel.SsidRole) || "";
        }
        return "";
    }

    function setWifiEnabled(enable) {
        handler.enableWireless(enable);
    }

    readonly property bool airplaneMode: PlasmaNM.Configuration.airplaneModeEnabled

    function setAirplaneMode(enable) {
        // KDE (Toolbar.qml): hem handler'a hem Configuration'a yazılır.
        handler.enableAirplaneMode(enable);
        PlasmaNM.Configuration.airplaneModeEnabled = enable;
    }

    // KDE imzaları: activateConnection(ConnectionPath, DevicePath, SpecificPath),
    // addAndActivateConnection(DevicePath, SpecificPath[, password]).
    function activateNetwork(connectionPath, devicePath, specificPath, password) {
        if (connectionPath) {
            handler.activateConnection(connectionPath, devicePath, specificPath);
        } else if (password) {
            handler.addAndActivateConnection(devicePath, specificPath, password);
        } else {
            handler.addAndActivateConnection(devicePath, specificPath);
        }
    }

    function deactivateNetwork(connectionPath, devicePath) {
        handler.deactivateConnection(connectionPath, devicePath);
    }

    // --- Bluetooth ---

    // Kaynak model bağlanmak yerine aşağıda atanır: singleton'ı bağlamak Qt'yi döngüye düşürüyor.
    PlasmaBt.DevicesProxyModel {
        id: btDevicesModel
        hideBlockedDevices: true
    }

    // KDE applet'inin cihaz listesi modeli.
    property alias bluetoothDevicesModel: btDevicesModel

    readonly property bool bluetoothAvailable: BluezQt.Manager.adapters.length > 0
    readonly property bool bluetoothEnabled: BluezQt.Manager.bluetoothOperational

    function setBluetoothEnabled(enable) {
        // KDE (bluedevil main.qml): rfkill engeli ve tüm adaptörlerin powered değeri.
        BluezQt.Manager.bluetoothBlocked = !enable;
        BluezQt.Manager.adapters.forEach(adapter => {
            adapter.powered = enable;
        });
    }

    // --- Rahatsız etme ---

    NotificationManager.Settings { id: notificationSettings }

    // Süre dolunca yeniden değerlensin diye saat.
    property double _dndTick: Date.now()
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: backend._dndTick = Date.now()
    }

    // Hesap KDE'nin Globals.qml'i ile aynı.
    readonly property bool dndEnabled: {
        _dndTick;
        if (!NotificationManager.Server.valid) {
            return false;
        }
        var inhibited = false;
        const until = notificationSettings.notificationsInhibitedUntil;
        if (until && !isNaN(until.getTime())) {
            inhibited = inhibited || (Date.now() < until.getTime());
        }
        inhibited = inhibited || notificationSettings.notificationsInhibitedByApplication;
        if (notificationSettings.inhibitNotificationsWhenFullscreen) {
            inhibited = inhibited || notificationSettings.fullscreenFocused;
        }
        if (notificationSettings.inhibitNotificationsWhenScreensMirrored) {
            inhibited = inhibited || notificationSettings.screensMirrored;
        }
        return inhibited;
    }

    function setDndEnabled(enable) {
        if (enable) {
            // KDE'nin toggle yöntemi: süresiz için tarih 1 yıl ileri atılır.
            const d = new Date();
            d.setFullYear(d.getFullYear() + 1);
            notificationSettings.notificationsInhibitedUntil = d;
            notificationSettings.save();
        } else {
            notificationSettings.notificationsInhibitedUntil = undefined;
            notificationSettings.revokeApplicationInhibitions();
            notificationSettings.fullscreenFocused = false;
            notificationSettings.screensMirrored = false;
            notificationSettings.save();
        }
    }

    // --- Gece rengi ---

    DBus.Properties {
        id: nightLightControl
        busType: DBus.BusType.Session
        service: "org.kde.KWin.NightLight"
        path: "/org/kde/KWin/NightLight"
        iface: "org.kde.KWin.NightLight"

        // Durum KWin D-Bus arayüzünden okunur (KDE'nin brightness/main.qml'i gibi).
        readonly property bool available: Boolean(properties.available)
        readonly property bool enabled: Boolean(properties.enabled)
        readonly property bool running: Boolean(properties.running)
        readonly property bool inhibited: Boolean(properties.inhibited)
        readonly property bool inhibitedFromApplet: NightLightInhibitor.inhibited
        readonly property bool togglable: !inhibited || inhibitedFromApplet
    }

    readonly property bool nightLightAvailable: nightLightControl.available

    // Etkin = açık, çalışırken ve engellenmemişken.
    readonly property bool nightLightActive: nightLightControl.enabled && nightLightControl.running && !nightLightControl.inhibited

    function toggleNightLight() {
        // Geçici kapat/aç; başka süreç engellemişse KDE'de de devre dışı.
        if (nightLightControl.togglable) {
            NightLightInhibitor.toggleInhibition();
        }
    }

    // --- Açık / koyu ---

    readonly property bool darkMode: DarkModeControl.darkMode

    function setDarkMode(enable) {
        DarkModeControl.darkMode = enable;
    }

    readonly property string currentThemeName: DarkModeControl.currentTheme

    // --- Güç profili ---

    PowerProfilesControl { id: powerProfilesControl }

    readonly property var powerProfiles: powerProfilesControl.profiles
    readonly property string activeProfile: powerProfilesControl.activeProfile
    readonly property bool powerProfilesAvailable: powerProfilesControl.profiles.length > 0
    // Profil engeli ve profili tutan uygulamalar (KDE PowerProfileItem).
    readonly property string profileInhibitionReason: powerProfilesControl.inhibitionReason
    readonly property var profileHolds: powerProfilesControl.profileHolds

    function setPowerProfile(profile) {
        if (!powerProfilesAvailable || profile === powerProfilesControl.activeProfile) {
            return;
        }
        // OSD gereksiz: değişiklik arayüzde görünüyor (KDE'nin isSilent bayrağı).
        powerProfilesControl.isSilent = true;
        powerProfilesControl.setProfile(profile);
    }

    // --- Ses ---

    SinkModel { id: paSinkModel }
    PulseObjectFilterModel {
        id: paSinkFilterModel
        filterOutInactiveDevices: true
        sourceModel: paSinkModel
    }

    // KDE applet'inin listelenen filtreli çıkış modeli.
    property alias sinkModel: paSinkFilterModel

    readonly property var defaultSink: PreferredDevice.sink ? PreferredDevice.sink : null
    readonly property real volume: defaultSink ? Math.max(0, Math.min(1, defaultSink.volume / PulseAudio.NormalVolume)) : 0
    readonly property bool muted: defaultSink ? defaultSink.muted : false

    function setVolume(value) {
        if (!defaultSink) {
            return;
        }
        defaultSink.volume = Math.round(PulseAudio.NormalVolume * Math.max(0, Math.min(1, value)));
    }

    function setMuted(enable) {
        if (!defaultSink) {
            return;
        }
        defaultSink.muted = enable;
    }

    // --- Parlaklık ---

    ScreenBrightnessControl { id: screenBrightnessControl }

    // QAbstractListModel'in QML'de bağlanabilir özelliği yok; KDE'nin Connections kalıbıyla okunur.
    property var _displaysInfo: []

    function _refreshDisplays() {
        const displays = screenBrightnessControl.displays;
        const roleIds = ["displayName", "isInternal", "brightness", "maxBrightness"]
            .map(name => displays.KItemModels.KRoleNames.role(name));
        _displaysInfo = [...Array(displays.rowCount()).keys()].map(i => {
            const modelIndex = displays.index(i, 0);
            return {
                displayName: displays.data(modelIndex, roleIds[0]),
                isInternal: displays.data(modelIndex, roleIds[1]),
                brightness: displays.data(modelIndex, roleIds[2]),
                maxBrightness: displays.data(modelIndex, roleIds[3]),
            };
        });
    }

    Connections {
        target: screenBrightnessControl.displays
        function onDataChanged() { backend._refreshDisplays(); }
        function onModelReset() { backend._refreshDisplays(); }
        function onRowsInserted() { backend._refreshDisplays(); }
        function onRowsMoved() { backend._refreshDisplays(); }
        function onRowsRemoved() { backend._refreshDisplays(); }
    }

    Component.onCompleted: {
        btDevicesModel.sourceModel = PlasmaBt.SharedDevicesStateProxyModel;
        _refreshDisplays();
    }

    readonly property bool brightnessAvailable: screenBrightnessControl.isBrightnessAvailable

    // Ana ekran: dahili panel varsa o, yoksa ilk ekran.
    readonly property var _mainDisplay: {
        for (var i = 0; i < _displaysInfo.length; i++) {
            if (_displaysInfo[i].isInternal) {
                return _displaysInfo[i];
            }
        }
        return _displaysInfo.length > 0 ? _displaysInfo[0] : null;
    }

    readonly property real brightness: {
        const display = _mainDisplay;
        return (display && display.maxBrightness > 0)
            ? Math.max(0, Math.min(1, display.brightness / display.maxBrightness))
            : 0;
    }

    function setBrightness(value) {
        const display = _mainDisplay;
        if (!display || !brightnessAvailable) {
            return;
        }
        // OSD gereksiz: değişiklik arayüzde görünüyor (KDE'nin isSilent bayrağı).
        screenBrightnessControl.isSilent = true;
        screenBrightnessControl.setBrightness(display.displayName,
            Math.round(display.maxBrightness * Math.max(0, Math.min(1, value))));
    }

    // --- Pil ---

    BatteryControlModel { id: batteryControl }

    // KDE BatteryItem'ın okuduğu roller bu modelden gelir.
    property alias batteriesModel: batteryControl

    readonly property bool hasBattery: batteryControl.hasBatteries
    readonly property int batteryPercent: batteryControl.percent
    readonly property bool charging: batteryControl.state === BatteryControlModel.Charging
    readonly property bool pluggedIn: batteryControl.pluggedIn
    // KDE main.qml'deki gibi yumuşatılmış süre.
    readonly property real remainingMsec: batteryControl.smoothedRemainingMsec
    readonly property int chargeStopThreshold: batteryControl.chargeStopThreshold
    readonly property bool hasInternalBatteries: batteryControl.hasInternalBatteries

    // --- Uyku engeli ---

    InhibitionControl { id: inhibitionControl }

    readonly property bool manuallyInhibited: inhibitionControl.isManuallyInhibited
    readonly property var requestedInhibitions: inhibitionControl.requestedInhibitions
    readonly property bool isLidPresent: inhibitionControl.isLidPresent
    readonly property bool triggersLidAction: inhibitionControl.triggersLidAction

    function setManuallyInhibited(inhibit) {
        // KDE main.qml: OSD yalnız popup kapalıyken; burada anahtarın kendisi geri bildirim.
        inhibitionControl.isSilent = true;
        if (inhibit) {
            inhibitionControl.inhibit(i18nd("plasma_applet_org.kde.plasma.battery", "The battery applet has enabled suppressing sleep and screen locking"));
        } else {
            inhibitionControl.uninhibit();
        }
    }
}