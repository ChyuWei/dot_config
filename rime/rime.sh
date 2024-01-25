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
linux_rime_base=$HOME/.local/share/fcitx5
mac_rime_base=$HOME/Library

if [[ $os_type == Linux ]]; then
    if [ -d "$linux_rime_base/rime" ]; then
        echo "mv $linux_rime_base/rime $linux_rime_base/rime.bak"
        mv "$linux_rime_base/rime" "$linux_rime_base/rime.bak"
    fi 
    ln -s $rime_ice "$linux_rime_base/rime"
elif [[ $os_type == Darwin ]]; then
    if [ -d "$mac_rime_base/Rime" ]; then
        echo "mv $mac_rime_base/Rime $mac_rime_base/Rime.bak"
        mv "$mac_rime_base/Rime" "$mac_rime_base/Rime.bak"
    fi
    ln -s $rime_ice "$mac_rime_base/Rime"
fi
