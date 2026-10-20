#!/usr/bin/env python3
"""Ro widget sözleşmesi denetimi (Ro-Theme-Docs 21 · WGT).

Her üst düzey klasör bir Plasma widget'ıdır (metadata.json + contents/). Denetlenenler:
- metadata.json geçerli JSON, KPackageStructure Plasma/Applet, kimlik org.ro.*;
- contents/ui/qmldir varsa klasördeki her .qml orada kayıtlı (WGT-08);
- her .qml/.js dosyasında SPDX lisans başlığı;
- QML'de elle renk yok: hex renk ve Qt.rgba(sayı...) yasak, renkler Kirigami.Theme'den (WGT-03);
- widget paketinde gereksiz tema kopyası (default/) yok (WGT-13);
- metadata.json KPlugin.Version, spec'teki varsayılan sürümle aynı;
- RoTokens.qml varsa Ro-Theme'in ürettiği kopyadır ve Style.qml köşeleri sayı değil token'dır (WGT-02/05);
- metadata Icon ro-* ise <widget>/icons/<ad>.svg var, SPDX başlıklı ve rengi temadan (ColorScheme-*/currentColor);
  config varsayılanı da aynı simge.
- servicemenu/: betik ve .desktop SPDX başlıklı, metinleri (_("…"), Name=) widget kataloğunda;
- çeviri: plasma_workspace kataloğu kullanılmaz (Fedora'da yok); widget'ın kendi alanındaki (i18n/i18nc) her
  metin <widget>/po/*.pot'ta ve her <dil>.po'da var. Kickoff'tan gelen metinler i18nd/i18ndc ile KDE kataloğundan.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors = []

def err(msg):
    errors.append(msg)

widgets = [p for p in ROOT.iterdir() if (p / 'metadata.json').is_file()]
if not widgets:
    err('hiç widget bulunamadı (metadata.json içeren üst düzey klasör yok)')

hex_color = re.compile(r'["\']#[0-9a-fA-F]{3,8}["\']')
rgba_literal = re.compile(r'Qt\.rgba\(\s*[0-9.]+\s*,')
own_i18n = re.compile(r'\bi18n\(\s*"((?:[^"\\]|\\.)*)"|\bi18nc\(\s*"(?:[^"\\]|\\.)*"\s*,\s*"((?:[^"\\]|\\.)*)"')
po_msgid = re.compile(r'^msgid "(.+)"$', re.M)

for w in sorted(widgets):
    name = w.name
    try:
        meta = json.loads((w / 'metadata.json').read_text(encoding='utf-8'))
    except json.JSONDecodeError as e:
        err(f'{name}: metadata.json geçersiz: {e}')
        continue
    if meta.get('KPackageStructure') != 'Plasma/Applet':
        err(f'{name}: KPackageStructure Plasma/Applet olmalı')
    pid = meta.get('KPlugin', {}).get('Id', '')
    if not pid.startswith('org.ro.'):
        err(f'{name}: KPlugin.Id org.ro.* olmalı (bulunan: {pid!r})')
    spec = (ROOT / 'packaging' / 'ro-widgets.spec').read_text(encoding='utf-8')
    spec_version = re.search(r'%\{!\?ro_version:([0-9.]+)\}', spec).group(1)
    if meta.get('KPlugin', {}).get('Version') != spec_version:
        err(f'{name}: metadata.json KPlugin.Version ({meta.get("KPlugin", {}).get("Version")}) spec sürümüyle ({spec_version}) aynı olmalı')
    if (w / 'default').exists():
        err(f'{name}: default/ klasörü pakete girmemeli (WGT-13)')
    ui = w / 'contents' / 'ui'
    qmldir = ui / 'qmldir'
    if qmldir.is_file():
        listed = set(re.findall(r'\s(\S+\.qml)\s*$', qmldir.read_text(encoding='utf-8'), re.M))
        for q in ui.glob('*.qml'):
            if q.name not in listed and q.name not in ('main.qml', 'config.qml', 'ConfigGeneral.qml'):
                err(f'{name}: {q.name} qmldir içinde kayıtlı değil (WGT-08)')
    tokens = ui / 'RoTokens.qml'
    if tokens.is_file():
        text = tokens.read_text(encoding='utf-8')
        if 'pragma Singleton' not in text or 'generate-theme.sh' not in text:
            err(f'{name}: RoTokens.qml Ro-Theme çıktısı değil; tools/sync-tokens ile kopyalayın')
        if not qmldir.is_file() or not re.search(r'^singleton RoTokens \S+ RoTokens\.qml$', qmldir.read_text(encoding='utf-8'), re.M):
            err(f'{name}: RoTokens qmldir içinde singleton olarak kayıtlı değil (WGT-08)')
    style = ui / 'Style.qml'
    if style.is_file():
        for i, line in enumerate(style.read_text(encoding='utf-8').splitlines(), 1):
            if re.match(r'\s*readonly property real radius\w*:\s*[0-9.]+\s*$', line):
                err(f'{style.relative_to(ROOT)}:{i}: köşe sayı olarak yazılmış; RoTokens kullanın (WGT-05)')
    icon = meta.get('KPlugin', {}).get('Icon', '')
    if icon.startswith('ro-'):
        svg = w / 'icons' / f'{icon}.svg'
        if not svg.is_file():
            err(f'{name}: metadata Icon {icon!r} için icons/{icon}.svg yok')
        else:
            text = svg.read_text(encoding='utf-8')
            if 'SPDX-License-Identifier' not in text:
                err(f'{svg.relative_to(ROOT)}: SPDX lisans başlığı yok')
            if 'id="current-color-scheme"' not in text or 'currentColor' not in text \
                    or re.search(r'(fill|stroke)="#[0-9a-fA-F]{3,8}"', text):
                err(f'{svg.relative_to(ROOT)}: renk temadan gelmeli (ColorScheme-* sınıfı + currentColor, elle renk yok)')
        main_xml = w / 'contents' / 'config' / 'main.xml'
        if main_xml.is_file() and 'name="icon"' in main_xml.read_text(encoding='utf-8') \
                and not re.search(r'name="icon"[^>]*>(?:(?!</entry>).)*<default>' + re.escape(icon) + '</default>',
                                  main_xml.read_text(encoding='utf-8'), re.S):
            err(f'{name}: config icon varsayılanı metadata Icon ({icon}) ile aynı olmalı')
    own_strings = set()
    for f in sorted(list(w.rglob('*.qml')) + list(w.rglob('*.js'))):
        rel = f.relative_to(ROOT)
        text = f.read_text(encoding='utf-8')
        if 'i18nd("plasma_workspace"' in text or "i18ndc(\"plasma_workspace\"" in text:
            err(f'{rel}: plasma_workspace çeviri kataloğu Fedora\'da yok; libkicker ya da Kickoff kataloğunu kullanın')
        if rel.name != 'tools.js':  # tools.js çeviri fonksiyonunu parametre olarak alır
            own_strings |= {a or b for a, b in own_i18n.findall(text)}
        if 'SPDX-License-Identifier' not in text:
            err(f'{rel}: SPDX lisans başlığı yok')
        if f.suffix == '.qml':
            for i, line in enumerate(text.splitlines(), 1):
                code = line.split('//', 1)[0]
                if hex_color.search(code) or rgba_literal.search(code):
                    err(f'{rel}:{i}: elle renk (WGT-03): {line.strip()}')

    # Dolphin/masaüstü sağ tık menüsü: betikteki _("…") ve .desktop'taki Name= metinleri de aynı katalogda
    service_dir = w / 'servicemenu'
    if service_dir.is_dir():
        for f in sorted(p for p in service_dir.iterdir() if p.is_file()):
            text = f.read_text(encoding='utf-8')
            if 'SPDX-License-Identifier' not in text:
                err(f'{f.relative_to(ROOT)}: SPDX lisans başlığı yok')
            if f.suffix == '.desktop':
                own_strings |= set(re.findall(r'^Name=(.+)$', text, re.M))
            else:
                own_strings |= set(re.findall(r'\b_\(\s*"((?:[^"\\]|\\.)*)"\s*\)', text))

    po_dir = w / 'po'
    pots = list(po_dir.glob('*.pot')) if po_dir.is_dir() else []
    if own_strings and not pots:
        err(f'{name}: kendi çeviri alanında metin var ama po/*.pot yok: {sorted(own_strings)}')
    for pot in pots:
        ids = set(po_msgid.findall(pot.read_text(encoding='utf-8')))
        for missing in sorted(own_strings - ids):
            err(f'{name}: "{missing}" {pot.name} içinde yok')
        for po in sorted(po_dir.glob('*.po')):
            for missing in sorted(ids - set(po_msgid.findall(po.read_text(encoding='utf-8')))):
                err(f'{name}: "{missing}" po/{po.name} içinde yok')

for e in errors:
    print(f'[FAIL] {e}')
print(f'widget: {len(widgets)}, hata: {len(errors)}')
sys.exit(1 if errors else 0)
