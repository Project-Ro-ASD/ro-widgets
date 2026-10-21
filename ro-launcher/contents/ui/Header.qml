/*
    SPDX-FileCopyrightText: 2026 Hasan OKSUZ

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.kcmutils as KCM

Item {
    id: root
    height: 54

    signal backgroundClicked()
    signal searchRequested()
    // Arama çubuğundaki klavye olayları; FullRepresentation NormalPage'e bağlar
    signal searchAccepted()
    signal searchNavigate(int delta)
    signal overlayCloseRequested()

    // Güç menüsü açıkken Esc sadece onu kapatsın, launcher'ı değil
    property bool overlayOpen: false

    property Item avatar: userAvatarRect
    property Item configureButton: configBtn
    property Item pinButton: null

    // Tema renkleri bu bileşenin bulunduğu yerden (popup) kalıtılsın diye yerel örnek
    readonly property Style st: styleItem
    Style {
        id: styleItem
    }

    // Profil fotoğrafı sistem ayarlarından değişince dosya aynı yolda kalır (AccountsService / ~/.face.icon): hem KUser hem
    // Image önbelleği eski değeri tutar. Launcher her açılışta KUser'ı yeniden kurar ve adrese revizyon ekler.
    property int faceRevision: 0
    Component {
        id: kuserComponent
        KCoreAddons.KUser {}
    }
    Loader {
        id: kuserLoader
        sourceComponent: kuserComponent
    }
    readonly property var kuser: kuserLoader.item
    readonly property string faceUrl: {
        const url = kuser?.faceIconUrl?.toString() ?? "";
        return url.length > 0 ? url + "?v=" + faceRevision : "";
    }
    function refreshUser() {
        faceRevision++;
        kuserLoader.active = false;
        kuserLoader.active = true;
    }

    Connections {
        target: kickoff
        function onExpandedChanged() {
            if (kickoff.expanded) {
                root.refreshUser();
            }
            if (!kickoff.expanded) {
                innerSearch.clear();
                innerSearch.focus = false;
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        // Profil Alanı
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            Item {
                id: userAvatarRect
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: root.st.glassRaised
                    border.color: root.st.border
                    border.width: root.st.borderWidth
                }

                Image {
                    id: userAvatarImg
                    anchors.fill: parent
                    source: root.faceUrl
                    cache: false
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }

                Rectangle {
                    id: avatarMask
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: userAvatarImg
                    maskSource: avatarMask
                    visible: userAvatarImg.status === Image.Ready && userAvatarImg.source.toString().length > 0
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: "user"
                    visible: userAvatarImg.status !== Image.Ready || userAvatarImg.source.toString().length === 0
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: KCM.KCMLauncher.openSystemSettings("kcm_users")
                }
            }

            PlasmaComponents.Label {
                text: kuser && kuser.fullName && kuser.fullName.length > 0 ? kuser.fullName : (kuser?.loginName ?? "")
                font.pointSize: root.st.fontNormal
                font.weight: Font.DemiBold
                color: Kirigami.Theme.textColor
                Layout.maximumWidth: 160
                Layout.preferredWidth: Math.min(implicitWidth, 160)
                elide: Text.ElideRight
            }
        }

        // Ayarlar Butonu
        Rectangle {
            id: configBtn
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 38
            Layout.preferredHeight: 38
            radius: root.st.radiusItem
            color: sHov.pressed ? root.st.pressed : (sHov.containsMouse ? root.st.hover : "transparent")

            Behavior on color { ColorAnimation { duration: root.st.durationShort } }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 22
                height: 22
                source: "configure"
            }

            MouseArea {
                id: sHov
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: KCM.KCMLauncher.openSystemSettings("")
            }
        }

        // Arama Çubuğu
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            Layout.alignment: Qt.AlignVCenter
            radius: height / 2
            color: root.st.glassRaised
            // Vurgu rengi sadece odaktayken. Kalınlık sabit: değişirse içerik kaymış gibi görünüyor.
            border.color: innerSearch.activeFocus ? root.st.accent : root.st.border
            border.width: root.st.borderWidth

            Behavior on border.color { ColorAnimation { duration: root.st.durationShort } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 12
                spacing: 8

                Kirigami.Icon {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    source: "search"
                    opacity: 0.6
                }

                QQC2.TextField {
                    id: innerSearch
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    background: null
                    // Stilin kendi dolgusu metni ikonla hizasız ve odakta oynak yapıyordu
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    placeholderText: i18nd("libplasma6", "Search…")
                    font.pointSize: root.st.fontNormal
                    verticalAlignment: Text.AlignVCenter
                    color: Kirigami.Theme.textColor

                    Component.onCompleted: {
                        if (kickoff) {
                            kickoff.searchField = innerSearch;
                        }
                    }

                    // Esc kabul edilmezse yukarı yayılır ve Plasma launcher'ı kapatır (stok Kickoff davranışı)
                    Keys.onPressed: event => {
                        switch (event.key) {
                        case Qt.Key_Escape:
                            if (root.overlayOpen) {
                                root.overlayCloseRequested();
                                event.accepted = true;
                            }
                            break;
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            root.searchAccepted();
                            event.accepted = true;
                            break;
                        case Qt.Key_Down:
                            root.searchNavigate(1);
                            event.accepted = true;
                            break;
                        case Qt.Key_Up:
                            root.searchNavigate(-1);
                            event.accepted = true;
                            break;
                        }
                    }

                    TapHandler {
                        onTapped: root.searchRequested()
                    }
                }

                Kirigami.Icon {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    source: "edit-clear"
                    // Yerini hep korusun: görünüp kaybolurken metin alanı daralıp genişlemesin
                    readonly property bool shown: innerSearch.text.length > 0
                    enabled: shown
                    opacity: shown ? (cMouse.containsMouse ? 1.0 : 0.6) : 0.0

                    MouseArea {
                        id: cMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: innerSearch.clear()
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.backgroundClicked()
    }
}
