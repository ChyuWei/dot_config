#!/usr/bin/env python3

import os
import sys
import time
import shutil
import subprocess
import argparse


def backup_rime(path):
    if os.path.exists(path):
        backup_path = path + int(time.time()) + ".bak"
        shutil.move(path, backup_path)
        print("Backup Rime config file to: " + backup_path)


class MacRimeDeploy:
    RIME = "squirrel"
    CONFIG_PATH = os.path.expanduser("~/Library/Rime")

    def check_rime_install(self):
        output = subprocess.getoutput("brew list")
        return self.RIME in output

    def deploy_rime(self):
        if self.check_rime_install():
            return True
        res = subprocess.run(["brew", "install", "--cask", self.RIME])
        if res.returncode != 0:
            print("Install Rime failed\n")
            return False

        print("Install Rime successfully\n")

    def deploy_plan(self):
        self.delete_and_backup()

        # cmd = f"git clone https://github.com/iDvel/rime-ice.git {self.CONFIG_PATH} --depth 1"
        cmd = f"git clone https://github.com/amzxyz/rime-wanxiang.git {self.CONFIG_PATH} --depth 1"
        res = subprocess.run(cmd.split())
        if res.returncode != 0:
            print("Install rime-ice failed\n")
            return False
        print("Install rime-ice success\n")

        self.deploy_config()

    def deploy_config(self):
        # shutil.copyfile(
        #     "./default.custom.yaml", f"{self.CONFIG_PATH}/default.custom.yaml"
        # )
        shutil.copyfile(
            "./squirrel.custom.yaml", f"{self.CONFIG_PATH}/squirrel.custom.yaml"
        )
        print("Install custom config success\n")

    def deploy_all(self):
        if not self.deploy_rime():
            return False

        if not self.deploy_plan():
            return False

    def delete_and_backup(self):
        if os.path.exists(self.CONFIG_PATH) and os.path.isdir(self.CONFIG_PATH):
            shutil.move(self.CONFIG_PATH, self.CONFIG_PATH + ".back")


def main():
    parser = argparse.ArgumentParser(prog="rime-installer")
    parser.add_argument("action", choices=["install", "update", "delete"])
    args = parser.parse_args()

    deploy = None
    if sys.platform == "darwin":
        print("MacOS\n")
        deploy = MacRimeDeploy()
    else:
        return

    if args.action == "update":
        deploy.deploy_config()
    elif args.action == "install":
        deploy.deploy_all()
    elif args.action == "delete":
        deploy.delete_and_backup()


if __name__ == "__main__":
    main()
