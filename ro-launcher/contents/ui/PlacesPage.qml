/*
 * SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents

BasePage {
    id: root

    sideBarComponent: KickoffListView {
        id: sideBar
        focus: true // needed for Loaders
        model: placesCategoryModel
        isSidebar: true
        delegate: KickoffListDelegate {
            id: delegate
            url: ""
            description: ""
            width: view.availableWidth
            isCategoryListItem: true
            isMultilineText: false
            background: PlasmaExtras.Highlight {
                // I have to do this for it to actually fill the item for some reason
                anchors.fill: parent
                active: false
                hovered: delegate.mouseArea.containsMouse || delegate.ListView.isCurrentItem
                visible: !delegate.isSeparator && hovered
            }
        }
    }

    contentAreaComponent: KickoffListView {
        id: contentArea
        mainContentView: true
        focus: true
        objectName: "frequentlyUsedView"
        readonly property int categoryIndex: {
            root.categoryRevision; // kenar çubuğu yeniden kurulunca yeniden hesapla
            const row = root.sideBarItem ? placesCategoryModel.get(root.sideBarItem.currentIndex) : null;
            return row ? row.roCategoryIndex : -1;
        }
        model: {
            if (categoryIndex >= 0) {
                return kickoff.categoryStore.models[categoryIndex] ?? null;
            }
            switch (root.sideBarItem.currentIndex) {
            case 0: return kickoff.computerModel
            case 1: return kickoff.recentUsageModel
            case 2: return kickoff.frequentUsageModel
            }
            return null;
        }
        onActiveFocusChanged: if (activeFocus && count < 1) {
            (root.sideBarItem as Item).forceActiveFocus()
        }

        // Boş kullanıcı kategorisi
        PlasmaComponents.Label {
            anchors.centerIn: parent
            width: parent.width - 48
            visible: contentArea.categoryIndex >= 0 && contentArea.count === 0
            text: i18n("Right-click an application and choose “Add to Category”.")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            opacity: 0.7
        }
    }

    // Kullanıcı kategorileri (CategoryStore): üç sabit satırın altında ayırıcı, kategoriler ve
    // "Yeni Kategori…". Yeni kategori eklenince o seçilir.
    property int categoryRevision: 0
    property int categoryCountBefore: 0
    function rebuildCategories() {
        const store = kickoff.categoryStore;
        const previous = root.sideBarItem ? root.sideBarItem.currentIndex : 0;
        while (placesCategoryModel.count > 3) {
            placesCategoryModel.remove(3);
        }
        const categories = store.enabled ? store.categories : [];
        if (store.enabled) {
            placesCategoryModel.append({ display: "", decoration: "", roCategoryIndex: -1, isSeparator: true });
            categories.forEach((c, i) => placesCategoryModel.append({ display: c.name, decoration: "folder", roCategoryIndex: i, isSeparator: false }));
            placesCategoryModel.append({ display: i18n("New Category…"), decoration: "list-add", roCategoryIndex: -2, isSeparator: false });
        }
        if (root.sideBarItem) {
            if (categories.length > root.categoryCountBefore && root.categoryCountBefore >= 0 && root.T.StackView.status === T.StackView.Active) {
                root.sideBarItem.currentIndex = 3 + categories.length; // yeni eklenen (ayırıcıdan sonra)
            } else {
                root.sideBarItem.currentIndex = Math.min(previous, 2 + (categories.length > 0 ? categories.length + 1 : 0));
            }
        }
        root.categoryCountBefore = categories.length;
        root.categoryRevision++;
    }

    Connections {
        target: kickoff.categoryStore
        function onCategoriesChanged() { root.rebuildCategories(); }
        function onEnabledChanged() { root.rebuildCategories(); }
    }

    // Ayırıcıya ya da "Yeni Kategori…" satırına (fare üstüne gelince, basınca) seçim gitmesin
    Connections {
        target: root.sideBarItem
        function onCurrentIndexChanged() {
            const row = placesCategoryModel.get(root.sideBarItem.currentIndex);
            if (row && (row.isSeparator || row.roCategoryIndex === -2)) {
                root.sideBarItem.currentIndex = root.lastSelectableIndex;
            } else {
                root.lastSelectableIndex = root.sideBarItem.currentIndex;
            }
        }
    }
    property int lastSelectableIndex: 0

    // we make our model ourselves
    ListModel {
        id: placesCategoryModel
        ListElement { display: "Computer"; decoration: "computer"; roCategoryIndex: -1; isSeparator: false }
        ListElement { display: "History"; decoration: "view-history"; roCategoryIndex: -1; isSeparator: false }
        ListElement { display: "Frequently Used"; decoration: "clock"; roCategoryIndex: -1; isSeparator: false }
        Component.onCompleted: {
            // Can't use a function in a QML ListElement declaration
            placesCategoryModel.setProperty(0, "display", i18ndc("plasma_applet_org.kde.plasma.kickoff", "category in Places sidebar", "Computer"))
            placesCategoryModel.setProperty(1, "display", i18ndc("plasma_applet_org.kde.plasma.kickoff", "category in Places sidebar", "History"))
            placesCategoryModel.setProperty(2, "display", i18ndc("plasma_applet_org.kde.plasma.kickoff", "category in Places sidebar", "Frequently Used"))
            if (KickoffSingleton.powerManagement.data["PowerDevil"]
                && KickoffSingleton.powerManagement.data["PowerDevil"]["Is Lid Present"]) {
                placesCategoryModel.setProperty(0, "decoration", "computer-laptop")
            }
            root.categoryCountBefore = -1; // ilk kurulumda seçim değişmesin
            root.rebuildCategories();
        }
    }
    // NormalPage doesn't get destroyed when deactivated, so the binding uses
    // StackView.status and visible. This way the bindings are reset when
    // NormalPage is Activated again.
    Binding {
        target: kickoff
        property: "sideBar"
        value: root.sideBarItem
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }
    Binding {
        target: kickoff
        property: "contentArea"
        value: root.contentAreaItem // NOT root.contentAreaItem.currentItem
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }
}
