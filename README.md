# ro-widgets

Ro Desktop'un Plasma widget'ları. Her üst düzey klasör bir Plasma widget paketidir (plasmoid).

| Klasör | Widget kimliği | Ne |
|---|---|---|
| `ro-launcher/` | `org.ro.launcher` | Ro panelinin uygulama başlatıcısı (Plasma Kickoff tabanlı) |

## Tema ile ilişki

Görsel kurallar Ro-Theme'in karar belgesindedir (Ro-Theme-Docs · 21 widget sözleşmesi, `WGT-*`). Kısaca:

- **Renkler** yalnızca `Kirigami.Theme`'den gelir; elle hex ya da sabit `Qt.rgba` yok (WGT-03). Kullanıcı vurgu
  rengini değiştirirse widget de değişir.
- **Popup'ın dış köşesini, gölgesini ve camını** widget değil Plasma stili çizer (WGT-04).
- **Stil nesneleri** popup'ın görsel ağacı içinde oluşturulur; panel bağlamında oluşturulan stil yanlış renk
  setini alır (WGT-07).
- **Singleton'lar** `qmldir` ile kaydedilir; `qmldir` varken kayıtsız tipler görünmez (WGT-08).
- **Köşe, boşluk ve süreler** Ro token'larından gelir (WGT-02). Ro-Theme'in ürettiği `RoTokens.qml` widget'ın
  `contents/ui/` klasörüne kopyalanır ve `qmldir`'de singleton olarak kaydedilir; widget Ro-Theme kurulu olmasa da
  çalışır. İç köşeler: kart `RoTokens.radiusMd` (12), kart içindeki öğe `RoTokens.radiusSm` (8) (WGT-05). Ölçüler
  `Kirigami.Units` ya da token; sabit piksel yok (WGT-09).
- Düğme, alan ve liste için Plasma bileşenleri kullanılır (WGT-11).
- **Simge:** Widget'ın kendi simgesi `<widget>/icons/<ad>.svg`; paket `hicolor/scalable/apps`'e kurar. Renk
  `ColorScheme-*` sınıfıyla temadan gelir. ro-launcher'ın simgesi `ro-start` (Ro logosunun halkaları).

Ro-Theme bu pakete bağımlı değildir. Ro'nun panel yerleşim betiği `org.ro.launcher` kuruluysa onu, değilse
Kickoff'u kullanır (WGT-14).

## Denetim ve derleme

```sh
python3 tools/check-widgets.py      # widget sözleşmesi (SPDX, qmldir, elle renk, default/ yok, token köşeleri)
python3 -m unittest discover -s tests # servis menüsü betiği birim testleri
tools/sync-tokens                   # Ro-Theme token'ları değişince: RoTokens.qml kopyalarını ../Ro-Theme'den güncelle
tools/sync-tokens --check           # kopyalar Ro-Theme main ile aynı mı (CI'da uyarı)
tools/project-ci                    # CI: sözleşme + QML sözdizimi + RPM (Fedora 44 konteyneri)
tools/build-rpm 0.1.7 noarch out/   # ro-widgets RPM ve SRPM
```

Yerel deneme (yalnız kendi kullanıcınız):

```sh
kpackagetool6 --type Plasma/Applet --upgrade ro-launcher || kpackagetool6 --type Plasma/Applet --install ro-launcher
```

Paket kurulunca `~/.local/share/plasma/plasmoids/org.ro.launcher` silinmeli; kullanıcı klasöründeki kopya sistem
paketini gölgeler.

## Sürüm çıkarmak

1. `packaging/ro-widgets.spec`: varsayılan sürüm (`%{!?ro_version:X.Y.Z}`) ve `%changelog` girdisi.
2. Her widget'ın `metadata.json` → `KPlugin.Version` aynı sürüm (`check-widgets.py` denetler).
3. PR merge edildikten sonra `main` üzerinde `vX.Y.Z` etiketi; yayın iş akışı paketi etiketten derler ve yayınlar.

## ro-launcher: kullanıcı kategorileri

- Kullanıcı kendi uygulama kategorilerini açar (Oyunlar, Ofis…). Ana ekranda Favorilerin altında katlanabilir
  kartlar (en fazla iki satır, fazlası "Tümünü göster"); Favoriler, kategoriler ve "+" birlikte kayar, launcher her
  açılışta en üstten başlar. Klasik modda aynı kategoriler Places kenar çubuğundadır.
- Uygulama eklemek: herhangi bir uygulamada sağ tık → "Kategoriye Ekle ▸". Kategori başlığında sağ tık ya da
  "⋮": yeniden adlandır, taşı, sil (uygulamalar silinmez).
- Dolphin ve masaüstünde bir uygulamaya (`.desktop`) sağ tık → "Ro Launcher Kategorisine Ekle…": kategori listesi
  (kdialog) açılır, seçim Plasma'nın betik arayüzüyle paneldeki her Ro Launcher'a yazılır; launcher hemen gösterir.
  Panelde Ro Launcher yoksa bunu söyler. Dosyalar: `ro-launcher/servicemenu/` (betik `/usr/libexec/ro-widgets/`,
  menü `/usr/share/kio/servicemenus/`; menünün çevirileri derlemede `tools/desktop-i18n.py` ile `po/`'dan).
- Veri widget ayarında (`customCategories`, JSON); ayarlardaki "Özel kategorileri göster" ile kapatılır.
  Kod: `CategoryStore.qml` (veri, menüler), `CategoryDialog.qml` (ad/silme penceresi).

## Çeviriler

- Kickoff'tan gelen metinler KDE'nin kendi kataloglarından çevrilir; yeni çeviri tutulmaz:
  `i18nd("plasma_applet_org.kde.plasma.kickoff", …)`/`i18ndc(…)`, oturum ve güç metinleri `libkicker`,
  arama `libplasma6`. `plasma_workspace` kataloğu Fedora'da yoktur, kullanılmaz (`check-widgets.py` denetler).
- Yalnız Ro'ya özgü metinler widget'ın kendi alanındadır (`i18n`/`i18nc`) ve `<widget>/po/` altında çevrilir:
  `.pot` şablonu ve Kickoff'un çevrildiği her dil için `<dil>.po`. Yeni metin eklenince `.pot` ve bütün `.po`
  dosyalarına girer (`check-widgets.py` denetler); paket derlenirken `msgfmt` ile `/usr/share/locale`'e kurulur.
- `metadata.json` açıklamasının çevirileri `Description[<dil>]` anahtarlarındadır.

## Yeni widget eklemek

1. `ro-<ad>/` klasörü: `metadata.json` (`KPlugin.Id` = `org.ro.<ad>`) ve `contents/`.
2. Her `.qml`/`.js` dosyasında SPDX lisans başlığı.
3. `packaging/ro-widgets.spec` içindeki `%files` listesine `%{_datadir}/plasma/plasmoids/org.ro.<ad>` eklenir.
4. `python3 tools/check-widgets.py` temiz olmalı.

## Açık konular

- **Mimari:** Widget'lar `noarch` paket üretir; `.roasd/app.json` `architectures: ["noarch"]`. Şablonun doğrulayıcısı
  ve yayın iş akışı `noarch`'ı tek başına kabul edecek şekilde genişletildi (Ro-Repo üretici kaydı `noarch`'ı zaten
  destekliyor). Aynı değişiklik `ro-app-template`'e önerildi.
- **Sabit ölçüler:** %100, %150 ve büyük yazı tipiyle gerçek oturumda denendi (WGT-09). Popup ekranın
  kullanılabilir alanıyla sınırlı, kutucuk etiketleri genel yazı boyutunu izliyor. Kutucuk ve başlık gibi iç ölçüler
  mantıksal piksel olduğu için ölçekle büyüyor; bu iki durumda sorun çıkarmadı.

## Lisans

Kickoff'tan gelen dosyalar kendi SPDX başlıklarındaki lisansla (GPL-2.0-or-later, LGPL-2.0-or-later); Ro'nun
eklediği dosyalar GPL-2.0-or-later. Paket bütünü GPL-3.0-or-later olarak dağıtılır. Simgeler (`*/icons/`, Ro
logosundan türer) CC-BY-SA-4.0.
