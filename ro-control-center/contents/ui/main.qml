/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid

// Geçici deneme: yalnız Backend'i okur, hiçbir ayarı değiştirmez.
PlasmoidItem {
    id: root

    Backend { id: be }

    preferredRepresentation: fullRepresentation

    fullRepresentation: Item {
        Layout.minimumWidth: 300
        Layout.minimumHeight: 200

        Timer {
            interval: 4000
            running: true
            onTriggered: console.warn("RO-CC wifi=" + be.wifiEnabled + " ssid=" + be.wifiSsid + " bt=" + be.bluetoothAvailable + "/" + be.bluetoothEnabled + " dnd=" + be.dndEnabled + " night=" + be.nightLightAvailable + "/" + be.nightLightActive + " dark=" + be.darkMode + " theme=" + be.currentThemeName + " power=" + be.activeProfile + " " + JSON.stringify(be.powerProfiles) + " vol=" + be.volume + " muted=" + be.muted + " bright=" + be.brightnessAvailable + "/" + be.brightness + " bat=" + be.hasBattery + "/" + be.batteryPercent + "/" + be.charging)
        }
    }
}