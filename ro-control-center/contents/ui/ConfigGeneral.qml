/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property string cfg_layout
    property string cfg_layoutDefault

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: layoutCombo
            Kirigami.FormData.label: i18n("Layout:")
            textRole: "text"
            valueRole: "value"
            model: [
                { value: "ro", text: i18n("Classic") },
                { value: "kartlar", text: i18n("Tiles") },
                { value: "halka", text: i18n("Ring") },
                { value: "sekmeler", text: i18n("Panel") }
            ]
            // Seçim model dolduktan sonra yapılır; bağlamayla yapılınca indexOfValue -1 dönüp hep ilk düzen görünüyordu.
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(root.cfg_layout))
            onActivated: root.cfg_layout = currentValue
        }
    }
}
