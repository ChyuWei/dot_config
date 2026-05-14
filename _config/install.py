#!/usr/bin/env python3

import os
import shutil
import subprocess

def check_exist(path):
    return os.path.lexists(path)


def make_backup(path):
    if check_exist(path):
        shutil.move(path, path + '.backup')
        print(f'backup {path} to {path}.backup')

def make_softlink(src, dst):
    os.symlink(src, dst)
    print(f'create softlink {src} -> {dst}')

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

def install(app):
    src = os.path.join(SCRIPT_DIR, app)
    install_path = os.path.expanduser(f'~/.config/{app}')
    if os.path.islink(install_path) and os.readlink(install_path) == src:
        print(f'{install_path} already linked to {src}, skip')
        return
    make_backup(install_path)
    make_softlink(src, install_path)

def brew_install(formula):
    if shutil.which(formula.split('/')[-1]):
        print(f'{formula} already installed')
        return
    print(f'brew install {formula}')
    subprocess.run(['brew', 'install', formula], check=True)

def install_tmux_deps():
    # macism: switch input method to ABC on tmux prefix (see tmux.conf)
    brew_install('laishulu/homebrew/macism')

if __name__ == '__main__':
    install('ghostty')
    install('tmux')
    install_tmux_deps()

