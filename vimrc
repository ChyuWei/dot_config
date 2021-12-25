" vim: foldmarker={,} foldlevel=0 foldmethod=marker :

set nocompatible
set backspace=indent,eol,start


""" 展示 {
syntax enable
syntax on

set number
set ruler
set nowrap

set cursorline
set cursorcolumn

set nobackup
set nowritebackup
" set noswapfile

set cursorline
set cursorcolumn

set updatetime=300
set signcolumn=number

""" }

""" 折叠 {
set foldmethod=syntax
set nofoldenable
""" }

""" 编辑 {
set tabstop=4
set shiftwidth=4
set softtabstop=4
set smarttab
set expandtab

set encoding=utf-8

filetype on
filetype indent on
filetype plugin on
filetype plugin indent on
""" }

""" 插件 {
call plug#begin('~/.vim/plugged')

Plug 'easymotion/vim-easymotion'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'kana/vim-textobj-user'
Plug 'kana/vim-textobj-entire'

" Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

""" }

