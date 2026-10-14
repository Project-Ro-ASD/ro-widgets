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

Ro-Theme bu pakete bağımlı değildir. Ro'nun panel yerleşim betiği `org.ro.launcher` kuruluysa onu, değilse
Kickoff'u kullanır (WGT-14).

## Denetim ve derleme

```sh
python3 tools/check-widgets.py      # widget sözleşmesi (SPDX, qmldir, elle renk, default/ yok, token köşeleri)
tools/sync-tokens                   # Ro-Theme token'ları değişince: RoTokens.qml kopyalarını ../Ro-Theme'den güncelle
tools/sync-tokens --check           # kopyalar Ro-Theme main ile aynı mı (CI'da uyarı)
tools/project-ci                    # CI: sözleşme + QML sözdizimi + RPM (Fedora 44 konteyneri)
tools/build-rpm 0.1.0 x86_64 out/   # ro-widgets RPM ve SRPM
```

Yerel deneme (yalnız kendi kullanıcınız):

```sh
kpackagetool6 --type Plasma/Applet --upgrade ro-launcher || kpackagetool6 --type Plasma/Applet --install ro-launcher
```

Paket kurulunca `~/.local/share/plasma/plasmoids/org.ro.launcher` silinmeli; kullanıcı klasöründeki kopya sistem
paketini gölgeler.

## Yeni widget eklemek

1. `ro-<ad>/` klasörü: `metadata.json` (`KPlugin.Id` = `org.ro.<ad>`) ve `contents/`.
2. Her `.qml`/`.js` dosyasında SPDX lisans başlığı.
3. `packaging/ro-widgets.spec` içindeki `%files` listesine `%{_datadir}/plasma/plasmoids/org.ro.<ad>` eklenir.
4. `python3 tools/check-widgets.py` temiz olmalı.

## Açık konular

- **Mimari:** Widget'lar `noarch` paket üretir; `ro-app-template` sözleşmesi şimdilik yalnız `x86_64`/`aarch64`
  kabul ediyor. Ro-Repo yayın kaydından önce `noarch` desteği netleşmeli.
- **Sabit ölçüler:** popup 640×560, başlık 54, kutucuk 90×94, güç menüsü 410×108; %150–%200 ölçekte test edilip
  `Kirigami.Units`'e taşınmalı (WGT-09).

## Lisans

Kickoff'tan gelen dosyalar kendi SPDX başlıklarındaki lisansla (GPL-2.0-or-later, LGPL-2.0-or-later); Ro'nun
eklediği dosyalar GPL-2.0-or-later. Paket bütünü GPL-3.0-or-later olarak dağıtılır.
