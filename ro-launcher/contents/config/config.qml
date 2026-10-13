/*
    SPDX-FileCopyrightText: 2026 Hasan OKSUZ

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18nd("plasma_workspace", "General")
        icon: "preferences-desktop"
        source: "ConfigGeneral.qml"
    }
}
