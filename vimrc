set nocompatible
set backspace=indent,eol,start

set number
set ruler
set nowrap

set nobackup
set nowritebackup
" set noswapfile

set cursorline
set cursorcolumn

syntax enable
syntax on

" set ignorecase

set foldmethod=syntax
set nofoldenable

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

call plug#begin('~/.vim/plugged')

Plug 'easymotion/vim-easymotion'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'kana/vim-textobj-user'
Plug 'kana/vim-textobj-entire'

" Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()


