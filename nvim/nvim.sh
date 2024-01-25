#!/bin/bash


nvim_base=$(pwd)
nvchad=$nvim_base/NvChad

nvim_config_base=$HOME/.config/nvim

if [ -d $nvim_config_base ]; then
    echo "$nvim_config_base $nvim_config_base.bak"
    mv $nvim_config_base "$nvim_config_base.bak"
fi
ln -s $nvchad $nvim_config_base
