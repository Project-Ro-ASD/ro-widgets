/*
    SPDX-FileCopyrightText: 2026 Hasan OKSUZ

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kirigami as Kirigami

// Launcher'ın görsel token'ları: tek kaynak.
// Renkler yalnızca Kirigami.Theme'den türetilir; renk şeması değişince hepsi kendiliğinden güncellenir.
// Kural: hover nötr tondur, vurgu rengi (accent) sadece seçili öğe / klavye odağı / odaklı arama çubuğu içindir.
//
// ÖNEMLİ: Her bileşen kendi örneğini popup'ın görsel ağacı içinde oluşturmalı:
//     Style { id: styleItem }  +  readonly property Style st: styleItem
// Kirigami.Theme renkleri bulunduğu yerden kalıtılır; panel bağlamında (main.qml) oluşturulursa
// panelin renk setini alır ve popup'ta yanlış (ör. simsiyah) görünür.
Item {
    id: root

    visible: false

    function tint(amount) {
        return Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, amount)
    }

    function withAlpha(c, alpha) {
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }

    //BEGIN Cam yüzeyler: metin renginin yarı saydam katmanları; alttaki popup zemini
    // (tema şeffafsa KWin bulanıklığı) içinden görünür. Gradyan yok.
    readonly property color glass: withAlpha(Kirigami.Theme.textColor, 0.045)        // ana kart
    readonly property color glassRaised: withAlpha(Kirigami.Theme.textColor, 0.075)  // arama çubuğu, kapsüller
    readonly property color glassBorder: withAlpha(Kirigami.Theme.textColor, 0.10)
    readonly property color glassShadow: withAlpha(Qt.darker(Kirigami.Theme.backgroundColor, 2.5), 0.35)
    //END

    //BEGIN Durumlar (nötr)
    readonly property color hover: withAlpha(Kirigami.Theme.textColor, 0.08)
    readonly property color pressed: withAlpha(Kirigami.Theme.textColor, 0.14)
    readonly property color border: withAlpha(Kirigami.Theme.textColor, 0.12)
    readonly property color borderStrong: withAlpha(Kirigami.Theme.textColor, 0.20)
    readonly property color divider: withAlpha(Kirigami.Theme.textColor, 0.10)
    readonly property color textMuted: withAlpha(Kirigami.Theme.textColor, 0.65)
    //END

    //BEGIN Opak yüzeyler (kararma katmanının üstünde okunaklı kalması gerekenler)
    readonly property color surfaceSolid: Kirigami.Theme.backgroundColor
    // Karartma siyah değil: temanın kendi arka planının koyu hali
    readonly property color scrim: withAlpha(Qt.darker(Kirigami.Theme.backgroundColor, 1.9), 0.55)
    //END

    //BEGIN Vurgu
    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property color accentSoft: withAlpha(Kirigami.Theme.highlightColor, 0.22)
    readonly property color accentBorder: withAlpha(Kirigami.Theme.highlightColor, 0.60)
    readonly property color onAccent: Kirigami.Theme.highlightedTextColor
    readonly property color danger: Kirigami.Theme.negativeBackgroundColor
    readonly property color onDanger: Kirigami.Theme.negativeTextColor
    //END

    //BEGIN Şekil
    // Popup'ın dış köşesi Plasma stilinden gelir (Ro: radius.popup 18, iç boşluk 8). İç öğeler ondan
    // küçük olmalı ki iç içe köşeler uyumlu dursun: kart < dış köşe, kart içindeki öğeler < kart.
    readonly property real radiusSmall: 8
    readonly property real radiusMedium: 10
    readonly property real radiusLarge: 14
    readonly property real borderWidth: 1
    //END

    //BEGIN Tipografi (kullanıcının font ayarı/ölçeklemesiyle birlikte büyür)
    // Bazı temalarda (ör. yedek tema) smallFont defaultFont'tan büyük gelebiliyor; asla büyük olmasın
    readonly property real fontSmall: Math.min(Kirigami.Theme.smallFont.pointSize, Kirigami.Theme.defaultFont.pointSize)
    readonly property real fontNormal: Kirigami.Theme.defaultFont.pointSize
    //END

    //BEGIN Hareket
    readonly property int durationShort: Kirigami.Units.shortDuration
    readonly property int durationLong: Kirigami.Units.longDuration
    //END
}
