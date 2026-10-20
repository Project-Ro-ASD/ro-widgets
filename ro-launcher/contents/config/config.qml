/*
    SPDX-FileCopyrightText: 2026 Hasan OKSUZ

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18ndc("plasma_applet_org.kde.plasma.kickoff", "@title:group for configuration dialog page", "General")
        icon: "preferences-desktop"
        source: "ConfigGeneral.qml"
    }
}
