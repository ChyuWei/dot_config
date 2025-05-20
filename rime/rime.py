#!/usr/bin/env python3

import os
import sys
import time
import shutil
import subprocess

def backup_rime(path):
    if os.path.exists(path):
        backup_path = path + int(time.time()) + '.bak'
        shutil.move(path, backup_path)
        print('Backup Rime config file to: ' + backup_path)

class MacRimeDeploy:

    RIME = 'squirrel'
    CONFIG_PATH = os.path.expanduser('~/Library/Rime/')

    def check_rime_install(self):
        output = subprocess.getoutput("brew list")
        return self.RIME in output

    def deploy_rime(self):
        if self.check_rime_install():
            return True
        res = subprocess.run(['brew', 'install', '--cask', self.RIME])
        if res.returncode != 0:
            print('Install Rime failed\n')
            return False
        
        print('Install Rime successfully\n')

    def deploy_ice(self):
        cmd = f'git clone https://github.com/iDvel/rime-ice.git {self.CONFIG_PATH} --depth 1'
        res = subprocess.run(cmd.split())
        if res.returncode != 0:
            print('Install rime-ice failed\n')
            return False
        print('Install rime-ice success\n')

        self.deploy_config()

    def deploy_config(self):
        shutil.copyfile('./default.custom.yaml', f'{self.CONFIG_PATH}default.custom.yaml')
        shutil.copyfile('./squirrel.custom.yaml', f'{self.CONFIG_PATH}squirrel.custom.yaml')
        print('Install custom config success\n')

    def deploy_all(self):
        if not self.deploy_rime():
            return False 
        
        if not self.deploy_ice():
            return False

def main():
    if len(sys.argv) < 2:
        print('Usage: rime.py [--install|--update]')
        return

    deploy = None
    if sys.platform == 'win32':
        print('Windows\n')
        return
    elif sys.platform == 'darwin':
        print('MacOS\n')
        deploy = MacRimeDeploy()
    elif sys.platform == 'linux':
        print('Linux\n')
        return
    else:
        print('Unknown\n')
        return

    if sys.argv[1] == '--update':
        deploy.deploy_config()
    elif sys.argv[1] == '--install':
        deploy.deploy_all()
    else:
        print('Usage: rime.py [--install|--update]')


if __name__ == '__main__':
    main()
