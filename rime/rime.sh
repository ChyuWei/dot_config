#!/bin/bash

rime_base=$(pwd)
config_file0=default.custom.yaml
config_file1=squirrel.custom.yaml

cd "$rime_base/rime-ice"

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


linux_rime_base=$HOME/.local/share/fcitx5

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  if [ -d "$linux_rime_base/rime" ]; then
    echo "mv $linux_rime_base/rime $linux_rime_base/rime.bak"
    mv "$linux_rime_base/rime" "$linux_rime_base/rime.bak"
  fi 
  ln -s "$rime_base/rime-ice" "$linux_rime_base/rime"
fi
