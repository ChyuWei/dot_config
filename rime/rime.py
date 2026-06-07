#!/usr/bin/env python3
"""万象拼音 (Rime Wanxiang) 一键安装脚本 for macOS Squirrel."""

import os
import sys
import json
import time
import shutil
import zipfile
import subprocess
import tempfile
import argparse
import urllib.request
from pathlib import Path


REPO = "amzxyz/rime-wanxiang"
GRAM_URL = (
    "https://github.com/amzxyz/RIME-LMDG/releases/download/"
    "LTS/wanxiang-lts-zh-hans.gram"
)
CONFIG_PATH = os.path.expanduser("~/Library/Rime")
SQUIRREL_APP = "/Library/Input Methods/Squirrel.app"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

VARIANTS = [
    "base", "wx", "flypy", "hanxin", "moqi",
    "tiger", "wubi", "zrm", "shouyou", "shyplus",
]

# ── helpers ──────────────────────────────────────────────────────


def _github_api(path):
    url = f"https://api.github.com/{path}" if path.startswith("repos/") else \
          f"https://api.github.com/repos/{REPO}/{path}"
    req = urllib.request.Request(url)
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("X-GitHub-Api-Version", "2022-11-28")
    with urllib.request.urlopen(req) as resp:
        return json.load(resp)


def _progress_bar(done, total, width=30):
    """Terminal progress bar: [=====>    ] 45%  12.3/27.4 MB"""
    if total <= 0:
        # Unknown total: just show downloaded amount
        mb_done = done / (1024 * 1024)
        sys.stdout.write(f"\r  ... {mb_done:.1f} MB downloaded")
        sys.stdout.flush()
        return
    pct = done / total
    filled = int(width * pct)
    bar = "=" * (filled - 1) + ">" + " " * (width - filled) if filled > 0 \
          else " " * width
    mb_done = done / (1024 * 1024)
    mb_total = total / (1024 * 1024)
    sys.stdout.write(f"\r  [{bar}] {pct*100:5.1f}%  {mb_done:6.1f}/{mb_total:.1f} MB")
    sys.stdout.flush()


def _download(url, dest, label=None):
    """Download a file with a progress bar."""
    print(f"  ↓ {label or url}")

    def _hook(count, block_size, total_size):
        _progress_bar(count * block_size, total_size)

    urllib.request.urlretrieve(url, dest, reporthook=_hook)
    _progress_bar(1, 1)  # complete the bar
    print()  # newline


# ── steps ────────────────────────────────────────────────────────


def install_squirrel():
    result = subprocess.run(["brew", "list", "--cask"],
                            capture_output=True, text=True)
    if "squirrel" in result.stdout:
        print("✓ Squirrel already installed")
        return True

    print("Installing Squirrel via Homebrew ...")
    result = subprocess.run(["brew", "install", "--cask", "squirrel"])
    if result.returncode != 0:
        print("✗ Failed to install Squirrel")
        return False
    print("✓ Squirrel installed")
    return True


def backup_rime():
    path = Path(CONFIG_PATH)
    if not path.exists():
        return
    backup = Path(str(CONFIG_PATH) + ".back")
    if backup.exists():
        backup = Path(str(CONFIG_PATH) + f".back.{int(time.time())}")
    shutil.move(str(path), str(backup))
    print(f"✓ Backup → {backup}")


def install_scheme(variant, tag=None, nightly=False):
    if variant == "base":
        zip_name = "rime-wanxiang-base.zip"
    else:
        zip_name = f"rime-wanxiang-{variant}-fuzhu.zip"

    # resolve release
    if nightly:
        data = _github_api("releases/tags/dict-nightly")
    elif tag:
        data = _github_api(f"releases/tags/{tag}")
    else:
        data = _github_api("releases/latest")

    release_tag = data["tag_name"]
    assets = data["assets"]

    download_url = None
    for a in assets:
        if a["name"] == zip_name:
            download_url = a["browser_download_url"]
            break

    if download_url is None:
        print(f"✗ Asset '{zip_name}' not found in release {release_tag}")
        sys.exit(1)

    print(f"Release: {release_tag}  |  Variant: {variant}")

    with tempfile.TemporaryDirectory() as tmpdir:
        zip_path = os.path.join(tmpdir, zip_name)
        _download(download_url, zip_path, label=f"{zip_name} ({release_tag})")

        os.makedirs(CONFIG_PATH, exist_ok=True)

        with zipfile.ZipFile(zip_path, "r") as zf:
            zf.extractall(CONFIG_PATH)

    print(f"✓ Scheme extracted → {CONFIG_PATH}")


def install_grammar():
    gram_path = os.path.join(CONFIG_PATH, "wanxiang-lts-zh-hans.gram")
    _download(GRAM_URL, gram_path, label="wanxiang-lts-zh-hans.gram")
    print("✓ Grammar model installed")


def install_custom_config(symlink=False):
    for name in ("squirrel.custom.yaml", "default.custom.yaml"):
        src = os.path.join(SCRIPT_DIR, name)
        dst = os.path.join(CONFIG_PATH, name)
        if not os.path.exists(src):
            continue
        if os.path.exists(dst) or os.path.islink(dst):
            os.remove(dst)
        if symlink:
            os.symlink(src, dst)
            print(f"✓ {name} → {dst}")
        else:
            shutil.copyfile(src, dst)
            print(f"✓ {name} applied")


def clean_build():
    build_dir = os.path.join(CONFIG_PATH, "build")
    if os.path.exists(build_dir):
        shutil.rmtree(build_dir)
        print("✓ Build cache cleaned")


def redeploy_squirrel():
    if not os.path.exists(SQUIRREL_APP):
        print("⚠ Squirrel.app not found, skip redeploy")
        return

    squirrel_bin = os.path.join(SQUIRREL_APP, "Contents/MacOS/Squirrel")
    print("Redeploying Squirrel ...")
    try:
        subprocess.run([squirrel_bin, "--reload"], timeout=10)
        print("✓ Squirrel redeploy triggered")
    except Exception as e:
        print(f"⚠ Redeploy failed: {e}")


def print_post_install():
    print()
    print("=" * 50)
    print("  Installation complete!")
    print("=" * 50)
    print()
    print("After deploy, switch to Chinese mode and type a slash command")
    print("to choose your pinyin scheme, then redeploy once more:")
    print()
    print("  /flypy    → 小鹤双拼        /zrm      → 自然码")
    print("  /mspy     → 微软双拼        /sogou    → 搜狗双拼")
    print("  /pinyin   → 全拼             /znabc    → 智能ABC")
    print("  /ziguang  → 紫光双拼        /pyjj     → 拼音加加")
    print("  /gbpy     → 国标双拼        /lxsq     → 乱序17")
    print("  /zrlong   → 自然龙          /hxlong   → 汉心龙")
    print("  /jjf      → 间接辅助        /zjf      → 直接辅助")


# ── main ─────────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(
        prog="rime-installer",
        description="万象拼音 (Wanxiang) 一键安装脚本 for macOS Squirrel",
    )
    parser.add_argument(
        "action", choices=["install", "update", "delete", "config"],
        help="install: full setup | update: refresh scheme+gram+config | "
             "delete: backup & remove | config: symlink custom configs only",
    )
    parser.add_argument(
        "--variant", "-v", default="base", choices=VARIANTS,
        help="方案 variant (default: base)",
    )
    parser.add_argument(
        "--nightly", action="store_true",
        help="Use nightly rolling release instead of stable",
    )
    parser.add_argument(
        "--no-grammar", action="store_true",
        help="Skip grammar model download",
    )
    parser.add_argument(
        "--no-config", action="store_true",
        help="Skip custom config override",
    )
    parser.add_argument(
        "--skip-squirrel", action="store_true",
        help="Skip Squirrel frontend install (assume already installed)",
    )
    args = parser.parse_args()

    if sys.platform != "darwin":
        print("This script only supports macOS.", file=sys.stderr)
        sys.exit(1)

    # ── config ──
    if args.action == "config":
        install_custom_config(symlink=True)
        clean_build()
        redeploy_squirrel()
        return

    # ── delete ──
    if args.action == "delete":
        backup_rime()
        return

    # ── install ──
    if args.action == "install":
        if not args.skip_squirrel:
            if not install_squirrel():
                sys.exit(1)
        backup_rime()

    # ── update ──
    install_scheme(variant=args.variant, nightly=args.nightly)

    if not args.no_grammar:
        install_grammar()

    if not args.no_config:
        install_custom_config(symlink=True)

    clean_build()
    redeploy_squirrel()
    print_post_install()


if __name__ == "__main__":
    main()
