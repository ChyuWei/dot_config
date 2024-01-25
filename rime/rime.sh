#!/bin/bash

rime_base=$(pwd)
rime_ice=$rime_base/rime-ice

config_file0=default.custom.yaml
config_file1=squirrel.custom.yaml

cd $rime_ice

if [ -e "$config_file0" ]; then
    echo "rm $config_file0"
    rm "$config_file0"
fi
ln -s "../$config_file0" .

if [ -e "$config_file1" ]; then
    echo "rm $config_file1"
    rm "$config_file1"
fi
ln -s "../$config_file1" .


os_type=$(uname -s)
linux_config_base=$HOME/.local/share/fcitx5/rime
mac_config_base=$HOME/Library/Rime

if [[ $os_type == Linux ]]; then
    if [ -d $linux_config_base ]; then
        echo "mv $linux_config_base $linux_config_base.bak"
        mv $linux_config_base "$linux_config_base.bak"
    fi 
    ln -s $rime_ice $linux_config_base
elif [[ $os_type == Darwin ]]; then
    if [ -d $mac_config_base ]; then
        echo "mv $mac_config_base $mac_config_base.bak"
        mv $mac_config_base "$mac_config_base.bak"
    fi
    ln -s $rime_ice $mac_config_base
fi
