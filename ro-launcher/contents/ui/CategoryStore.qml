/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.private.kicker as Kicker

// Kullanıcının kendi uygulama kategorileri (Oyunlar, Ofis…). Veri widget ayarında JSON olarak durur
// (customCategories); her kategori için bir SimpleFavoritesModel uygulama adını, simgesini, sağ tık
// eylemlerini ve başlatmayı sağlar. Ana ekran ve klasik moddaki Places aynı veriyi gösterir.
Item {
    id: store

    visible: false

    // Plasmoid.configuration; main.qml bağlar
    property var config: null
    // Kategorilerin sağ tık menüsünde "Sık Kullanılanlara Ekle" çalışsın diye
    property var favoritesModel: null

    readonly property bool enabled: config?.showCustomCategories ?? true

    // [{ name, apps: ["org.kde.dolphin.desktop", …], collapsed }]
    property var categories: []
    // categories ile aynı sırada; her biri Kicker.SimpleFavoritesModel
    property var models: []

    // Ad girişi (yeni kategori / yeniden adlandırma) ve silme onayı FullRepresentation'daki
    // CategoryDialog'da açılır
    signal nameRequested(string mode, int index, string appId, string initialName)
    signal deleteRequested(int index, string name)
    // Pencere açıkken ana sayfa tuşları arama çubuğuna aktarmaz, pencereye yollar (CategoryDialog bağlar)
    property bool dialogOpen: false
    signal dialogKeyTyped(string text)
    signal dialogCloseRequested()

    Component {
        id: modelComponent
        Kicker.SimpleFavoritesModel {
            property int roCategoryIndex: -1
        }
    }

    Connections {
        target: store.config
        function onCustomCategoriesChanged() {
            store.load();
        }
    }

    onConfigChanged: load()
    onFavoritesModelChanged: {
        for (const m of models) {
            m.favoritesModel = favoritesModel;
        }
    }

    function load() {
        let parsed = [];
        try {
            parsed = JSON.parse(config?.customCategories || "[]");
        } catch (e) {
            parsed = [];
        }
        if (!Array.isArray(parsed)) {
            parsed = [];
        }
        categories = parsed
            .filter(c => c && typeof c.name === "string")
            .map(c => ({
                name: c.name,
                apps: Array.isArray(c.apps) ? c.apps.filter(a => typeof a === "string") : [],
                collapsed: c.collapsed === true,
            }));
        syncModels();
    }

    function save() {
        const text = JSON.stringify(categories);
        if (config && config.customCategories !== text) {
            config.customCategories = text; // onCustomCategoriesChanged → load()
        } else {
            syncModels();
        }
    }

    // Model sayısını kategori sayısına eşitler; var olan modelleri yeniden kurmaz, listeleri günceller
    function syncModels() {
        const list = models.slice();
        while (list.length > categories.length) {
            list.pop().destroy();
        }
        while (list.length < categories.length) {
            list.push(modelComponent.createObject(store, { favoritesModel: store.favoritesModel }));
        }
        for (let i = 0; i < categories.length; ++i) {
            list[i].roCategoryIndex = i;
            list[i].favorites = categories[i].apps;
        }
        models = list;
    }

    // Kicker kimliklerinde uygulamalar "org.kde.dolphin.desktop" ya da "preferred://browser";
    // etkinlik istatistiklerinden gelenlerde "applications:" öneki olabilir
    function normalizeId(id) {
        const s = String(id ?? "");
        return s.startsWith("applications:") ? s.substring(13) : s;
    }

    function isApplication(id) {
        const s = normalizeId(id);
        return s.endsWith(".desktop") || s.startsWith("preferred://");
    }

    function contains(index, appId) {
        return categories[index]?.apps.includes(normalizeId(appId)) ?? false;
    }

    function update(fn) {
        const copy = categories.map(c => ({ name: c.name, apps: c.apps.slice(), collapsed: c.collapsed }));
        fn(copy);
        categories = copy;
        save();
    }

    function addCategory(name, appId) {
        const trimmed = name.trim();
        if (trimmed.length === 0) return;
        update(list => list.push({ name: trimmed, apps: isApplication(appId) ? [normalizeId(appId)] : [], collapsed: false }));
    }

    function renameCategory(index, name) {
        const trimmed = name.trim();
        if (trimmed.length === 0 || !categories[index]) return;
        update(list => list[index].name = trimmed);
    }

    function removeCategory(index) {
        if (!categories[index]) return;
        update(list => list.splice(index, 1));
    }

    function moveCategory(index, delta) {
        const to = index + delta;
        if (!categories[index] || to < 0 || to >= categories.length) return;
        update(list => list.splice(to, 0, list.splice(index, 1)[0]));
    }

    function toggleCollapsed(index) {
        if (!categories[index]) return;
        update(list => list[index].collapsed = !list[index].collapsed);
    }

    function addApp(index, appId) {
        const id = normalizeId(appId);
        if (!categories[index] || !isApplication(id) || contains(index, id)) return;
        update(list => list[index].apps.push(id));
    }

    function removeApp(index, appId) {
        const id = normalizeId(appId);
        if (!categories[index]) return;
        update(list => list[index].apps = list[index].apps.filter(a => a !== id));
    }

    //BEGIN Sağ tık menüleri (ActionMenu, "_ro_category_" eylemlerini handleAction'a yollar)

    // Bir uygulamanın menüsüne eklenecekler. sourceModel bir kategorinin modeliyse "Kategoriden Kaldır" da gelir.
    function appActions(appId, sourceModel) {
        if (!enabled || !isApplication(appId)) return [];
        const id = normalizeId(appId);
        const actions = [];
        const sourceIndex = sourceModel?.roCategoryIndex ?? -1;
        if (sourceIndex >= 0) {
            actions.push({
                text: i18n("Remove from Category"),
                icon: "list-remove",
                actionId: "_ro_category_remove_app",
                actionArgument: { category: sourceIndex, app: id },
            });
        }
        const subActions = categories.map((c, i) => ({
            text: c.name,
            checkable: true,
            checked: c.apps.includes(id),
            actionId: "_ro_category_toggle_app",
            actionArgument: { category: i, app: id },
        }));
        if (subActions.length > 0) {
            subActions.push({ type: "separator" });
        }
        subActions.push({
            text: i18n("New Category…"),
            icon: "list-add",
            actionId: "_ro_category_new",
            actionArgument: { app: id },
        });
        actions.push({ text: i18n("Add to Category"), icon: "folder-new", subActions });
        return actions;
    }

    // Kategori başlığının menüsü
    function categoryActions(index) {
        return [
            { text: i18n("Rename…"), icon: "edit-rename", actionId: "_ro_category_rename", actionArgument: { category: index } },
            { text: i18n("Move Up"), icon: "go-up", enabled: index > 0, actionId: "_ro_category_move", actionArgument: { category: index, delta: -1 } },
            { text: i18n("Move Down"), icon: "go-down", enabled: index < categories.length - 1, actionId: "_ro_category_move", actionArgument: { category: index, delta: 1 } },
            { type: "separator" },
            { text: i18n("Delete Category"), icon: "edit-delete", actionId: "_ro_category_delete", actionArgument: { category: index } },
        ];
    }

    function handleAction(actionId, arg) {
        switch (actionId) {
        case "_ro_category_remove_app": removeApp(arg.category, arg.app); break;
        case "_ro_category_toggle_app":
            if (contains(arg.category, arg.app)) removeApp(arg.category, arg.app); else addApp(arg.category, arg.app);
            break;
        case "_ro_category_new": requestNewCategory(arg.app ?? ""); break;
        case "_ro_category_rename": nameRequested("rename", arg.category, "", categories[arg.category]?.name ?? ""); break;
        case "_ro_category_move": moveCategory(arg.category, arg.delta); break;
        case "_ro_category_delete": deleteRequested(arg.category, categories[arg.category]?.name ?? ""); break;
        }
    }
    //END

    function requestNewCategory(appId) {
        nameRequested("new", -1, appId ?? "", "");
    }

    function applyName(mode, index, appId, name) {
        if (mode === "rename") {
            renameCategory(index, name);
        } else {
            addCategory(name, appId);
        }
    }
}
