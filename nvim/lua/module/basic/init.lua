local util = require('util')

local M = {}

M.pkg = {
    "wbthomason/packer.nvim",
    "lewis6991/impatient.nvim",
    "nvim-lua/popup.nvim",
    "nvim-lua/plenary.nvim",
}

function M.keymap()
    util.keymap("", ";", "<Nop>")
    vim.g.mapleader = ";"
    vim.g.maplocalleader = ";"
end

function M.setup()
    M.keymap()
    require 'module.basic.options'
    vim.o.runtimepath = vim.o.runtimepath .. ",~/.opam/default/share/merlin/vim"
end

-- pcall(require, 'impatient')
require('impatient').enable_profile()

return M
