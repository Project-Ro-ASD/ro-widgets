#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Project Ro-ASD
# SPDX-License-Identifier: GPL-2.0-or-later
"""Bir .desktop dosyasının Name= satırlarına po/<dil>.po çevirilerini Name[<dil>]= olarak ekler.

Kullanım: tools/desktop-i18n.py <po-klasörü> <girdi.desktop> <çıktı.desktop>
Yorum satırları atılır; çevirisi olmayan dilde satır eklenmez (İngilizce kalır).
"""
import ast
import sys
from pathlib import Path


def parse_po(path):
    entries, msgid, msgstr, current = {}, None, None, None
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("msgid "):
            if msgid is not None:
                entries[msgid] = msgstr
            msgid, msgstr, current = ast.literal_eval(line[6:]), "", "id"
        elif line.startswith("msgstr "):
            msgstr, current = ast.literal_eval(line[7:]), "str"
        elif line.startswith('"') and current:
            if current == "id":
                msgid += ast.literal_eval(line)
            else:
                msgstr += ast.literal_eval(line)
    if msgid is not None:
        entries[msgid] = msgstr
    return entries


def main(po_dir, source, target):
    catalogs = {po.stem: parse_po(po) for po in sorted(Path(po_dir).glob("*.po"))}
    out = []
    for line in Path(source).read_text(encoding="utf-8").splitlines():
        if line.startswith("#"):
            continue
        out.append(line)
        if line.startswith("Name="):
            text = line[len("Name="):]
            for lang, entries in catalogs.items():
                translated = entries.get(text)
                if translated:
                    out.append(f"Name[{lang}]={translated}")
    Path(target).write_text("\n".join(out) + "\n", encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
