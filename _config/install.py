#!/usr/bin/env python3

import os
import shutil

def check_exist(path):
    return os.path.lexists(path)


def make_backup(path):
    if check_exist(path):
        shutil.move(path, path + '.backup')
        print(f'backup {path} to {path}.backup')

def make_softlink(src, dst):
    os.symlink(src, dst)
    print(f'create softlink {src} -> {dst}')

def install(app):
    install_path = os.path.expanduser(f'~/.config/{app}')
    make_backup(install_path)
    make_softlink(os.path.abspath(f'./{app}'), os.path.expanduser(f'~/.config/{app}'))

if __name__ == '__main__':
    install('ghostty')
    install('tmux')

