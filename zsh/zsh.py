#!/usr/bin/env python3
"""zsh config installer"""

import os
import sys
import shutil
import subprocess
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
HOME = Path.home()
LINK_DST = HOME / ".config" / "zsh"
ZSH_TEMPLATE = SCRIPT_DIR / "zshrc.template"
ZSH_LIB = SCRIPT_DIR / "zshrc.lib"


def info(msg: str):
    print(f"  \033[36m●\033[0m {msg}")


def ok(msg: str):
    print(f"  \033[32m✓\033[0m {msg}")


def warn(msg: str):
    print(f"  \033[33m⚠\033[0m {msg}")


def fail(msg: str):
    print(f"  \033[31m✗\033[0m {msg}")


def brew(formula: str):
    try:
        subprocess.run(["brew", "install", formula], check=True)
        ok(f"brew install {formula}")
    except subprocess.CalledProcessError:
        fail(f"brew install {formula}")


def symlink(src: Path, dst: Path):
    if dst.is_symlink() and os.readlink(str(dst)) == str(src):
        ok(f"{dst} → {src}")
        return
    if dst.exists() or dst.is_symlink():
        bak = Path(str(dst) + ".back")
        dst.rename(bak)
        info(f"backup {dst} → {bak}")
    dst.symlink_to(src)
    ok(f"{dst} → {src}")


def install_zoxide():
    brew("zoxide")


def install_zsh_config():
    """Symlink zsh/ → ~/.config/zsh."""
    LINK_DST.parent.mkdir(parents=True, exist_ok=True)
    symlink(SCRIPT_DIR, LINK_DST)


def install_zshrc():
    """Copy template to ~/.zshrc if missing."""
    zshrc = HOME / ".zshrc"
    if zshrc.exists() or zshrc.is_symlink():
        warn(f"~/.zshrc exists, skip")
        return
    shutil.copyfile(ZSH_TEMPLATE, zshrc)
    ok("~/.zshrc created from zshrc.template")


def main():
    print("zsh config install")
    install_zoxide()
    install_zsh_config()
    install_zshrc()
    print()
    ok("Done. exec zsh to reload.")


if __name__ == "__main__":
    main()
