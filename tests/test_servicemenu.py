#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Project Ro-ASD
# SPDX-License-Identifier: GPL-2.0-or-later
"""ro-launcher/servicemenu/ro-launcher-servicemenu betiği için birim testleri.

Betik uzantısız olduğu için importlib.machinery.SourceFileLoader ile yüklenir. Her test kendi geçici klasörünü
kurar ve XDG_DATA_HOME, XDG_CONFIG_HOME, RO_WIDGETS_SHARE değişkenlerini oraya yönler; gerçek ev klasörüne
dokunulmaz. Çalıştırma: python3 -m unittest discover -s tests
"""
import contextlib
import importlib.machinery
import importlib.util
import io
import os
import pathlib
import shutil
import stat
import sys
import tempfile
import unittest
from unittest import mock

NAME = "ro-launcher-add-to-category.desktop"
REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = REPO_ROOT / "ro-launcher" / "servicemenu" / "ro-launcher-servicemenu"

TEMPLATE_TEXT = "[Desktop Entry]\nType=Service\nName=Ro Launcher'a ekle\n"


def load_servicemenu():
    """Uzantısız betiği geçerli Python kaynağı gibi yükler (bayt kodu önbelleği yazılmaz)."""
    loader = importlib.machinery.SourceFileLoader("ro_launcher_servicemenu", str(SCRIPT))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    dont_write, sys.dont_write_bytecode = sys.dont_write_bytecode, True
    try:
        loader.exec_module(module)
    finally:
        sys.dont_write_bytecode = dont_write
    return module


class ServicemenuTest(unittest.TestCase):
    """Her test için ayrı geçici klasör ve yönlenmiş ortam değişkenleri kurar."""

    def setUp(self):
        self.tmp = pathlib.Path(tempfile.mkdtemp(prefix="ro-servicemenu-test-"))
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.data_home = self.tmp / "data"
        self.config_home = self.tmp / "config"
        self.share = self.tmp / "share"
        for path in (self.data_home, self.config_home, self.share):
            path.mkdir(parents=True)
        env = mock.patch.dict(os.environ, {
            "XDG_DATA_HOME": str(self.data_home),
            "XDG_CONFIG_HOME": str(self.config_home),
            "RO_WIDGETS_SHARE": str(self.share),
        })
        env.start()
        self.addCleanup(env.stop)
        self.sm = load_servicemenu()

    @property
    def target(self):
        return self.data_home / "kio" / "servicemenus" / NAME

    def make_template(self, content=TEMPLATE_TEXT):
        path = self.share / "servicemenu" / NAME
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def write_appletsrc(self, text):
        path = self.config_home / "plasma-org.kde.plasma.desktop-appletsrc"
        path.write_text(text, encoding="utf-8")
        return path


class LauncherPresentTest(ServicemenuTest):
    def test_ayar_dosyasi_yoksa_none(self):
        self.assertIsNone(self.sm.launcher_present())

    def test_launchersiz_dosya_false(self):
        self.write_appletsrc(
            "[Containments][1]\nplugin=org.kde.plasma.desktop\n"
            "[Containments][2]\nplugin=org.kde.plasma.panel\n"
        )
        self.assertIs(self.sm.launcher_present(), False)

    def test_launcher_satiri_true(self):
        self.write_appletsrc(
            "[Containments][1]\nplugin=org.kde.plasma.desktop\n"
            "[Containments][2][Applets][3]\nplugin=org.ro.launcher\n"
            "[Containments][2][Applets][4]\nplugin=org.kde.plasma.kickoff\n"
        )
        self.assertIs(self.sm.launcher_present(), True)

    def test_bosluklu_satir_true(self):
        # Betik satırı .strip() ile karşılaştırır.
        self.write_appletsrc("[Containments][2][Applets][3]\n  plugin=org.ro.launcher  \n")
        self.assertIs(self.sm.launcher_present(), True)

    def test_benzer_dogru_dizilim_false(self):
        self.write_appletsrc("[Containments][2][Applets][3]\nplugin=org.ro.launcher.backup\n")
        self.assertIs(self.sm.launcher_present(), False)


class EnableTest(ServicemenuTest):
    def test_sablonu_kopyalar_ve_0755_yapar(self):
        self.make_template()
        self.assertEqual(self.sm.enable(), 0)
        self.assertTrue(self.target.is_file())
        self.assertEqual(self.target.read_text(encoding="utf-8"), TEMPLATE_TEXT)
        self.assertEqual(stat.S_IMODE(self.target.stat().st_mode), 0o755)
        # Ara dosya geride kalmamalı.
        self.assertFalse(self.target.with_name(self.target.name + ".tmp").exists())

    def test_ust_klasoru_olusturur(self):
        self.make_template()
        self.assertFalse(self.target.parent.exists())
        self.assertEqual(self.sm.enable(), 0)
        self.assertTrue(self.target.parent.is_dir())

    def test_sablon_yoksa_1(self):
        self.assertEqual(self.sm.enable(), 1)
        self.assertFalse(self.target.exists())

    def test_mevcut_hedefi_degistirir(self):
        self.make_template(content="yeni\n")
        self.target.parent.mkdir(parents=True)
        self.target.write_text("eski\n", encoding="utf-8")
        self.assertEqual(self.sm.enable(), 0)
        self.assertEqual(self.target.read_text(encoding="utf-8"), "yeni\n")


class DisableTest(ServicemenuTest):
    def test_dosya_yoksa_hata_vermez(self):
        self.assertEqual(self.sm.disable(), 0)
        self.assertFalse(self.target.exists())

    def test_dosyayi_siler(self):
        self.make_template()
        self.assertEqual(self.sm.enable(), 0)
        self.assertTrue(self.target.is_file())
        self.assertEqual(self.sm.disable(), 0)
        self.assertFalse(self.target.exists())


class SyncTest(ServicemenuTest):
    def test_ayar_dosyasi_yoksa_durumu_birakir(self):
        # Hedef varsa olduğu gibi kalmalı.
        self.make_template()
        self.target.parent.mkdir(parents=True)
        self.target.write_text("mevcut\n", encoding="utf-8")
        self.assertEqual(self.sm.sync(), 0)
        self.assertEqual(self.target.read_text(encoding="utf-8"), "mevcut\n")
        # Hedef yoksa kurulmamalı.
        self.target.unlink()
        self.assertEqual(self.sm.sync(), 0)
        self.assertFalse(self.target.exists())

    def test_launcher_varsa_kurar(self):
        self.make_template()
        self.write_appletsrc("[Containments][2][Applets][3]\nplugin=org.ro.launcher\n")
        self.assertEqual(self.sm.sync(), 0)
        self.assertTrue(self.target.is_file())
        self.assertEqual(stat.S_IMODE(self.target.stat().st_mode), 0o755)

    def test_launcher_yoksa_siler(self):
        self.make_template()
        self.assertEqual(self.sm.enable(), 0)
        self.write_appletsrc("[Containments][1]\nplugin=org.kde.plasma.desktop\n")
        self.assertEqual(self.sm.sync(), 0)
        self.assertFalse(self.target.exists())

    def test_launcher_yok_hedef_yok(self):
        self.write_appletsrc("[Containments][1]\nplugin=org.kde.plasma.desktop\n")
        self.assertEqual(self.sm.sync(), 0)
        self.assertFalse(self.target.exists())


class MainTest(ServicemenuTest):
    def test_gecersiz_arguman_2(self):
        for argv in ([], ["bogus"], ["enable", "disable"], ["ENABLE"], ["--help"]):
            with self.subTest(argv=argv):
                err = io.StringIO()
                with contextlib.redirect_stderr(err):
                    self.assertEqual(self.sm.main(list(argv)), 2)
                self.assertEqual(err.getvalue(), self.sm.__doc__ + "\n")

    def test_enable_disable_komutlari(self):
        self.make_template()
        err = io.StringIO()
        with contextlib.redirect_stderr(err):
            self.assertEqual(self.sm.main(["enable"]), 0)
            self.assertTrue(self.target.is_file())
            self.assertEqual(self.sm.main(["disable"]), 0)
            self.assertFalse(self.target.exists())
        self.assertEqual(err.getvalue(), "")

    def test_sync_komutu(self):
        self.make_template()
        self.write_appletsrc("[Containments][2][Applets][3]\nplugin=org.ro.launcher\n")
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(self.sm.main(["sync"]), 0)
        self.assertTrue(self.target.is_file())


class SyncLaterTest(ServicemenuTest):
    """sync_later çatallanıp 6 sn uyuduğu için fork ve sleep mock'lanarak denenir."""

    def test_ust_surec_hemen_doner(self):
        with mock.patch.object(self.sm.os, "fork", return_value=1), \
                mock.patch.object(self.sm.time, "sleep") as sleep, \
                mock.patch.object(self.sm, "sync") as sync:
            self.assertEqual(self.sm.sync_later(), 0)
        sleep.assert_not_called()
        sync.assert_not_called()

    def test_alt_surec_6_sn_uyur_ve_sync_yapar(self):
        self.assertEqual(self.sm.DELAY, 6)
        with mock.patch.object(self.sm.os, "fork", side_effect=[0, 0]), \
                mock.patch.object(self.sm.os, "setsid") as setsid, \
                mock.patch.object(self.sm.time, "sleep") as sleep, \
                mock.patch.object(self.sm.os, "_exit") as ex, \
                mock.patch.object(self.sm, "sync", return_value=0) as sync:
            # Gerçek os._exit hiç dönmez; mock'landığı için işlev None ile biter.
            self.assertIsNone(self.sm.sync_later())
        setsid.assert_called_once_with()
        sleep.assert_called_once_with(6)
        sync.assert_called_once_with()
        ex.assert_called_once_with(0)


if __name__ == "__main__":
    unittest.main()