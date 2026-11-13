" 基础
filetype plugin indent on
syntax on
set mouse=a number relativenumber cursorline ruler showmode

" 编码
set encoding=utf-8 fileencodings=utf-8,gb18030,gbk,gb2312

" 搜索
set hlsearch incsearch ignorecase smartcase

" 缩进（4空格）
set expandtab tabstop=4 softtabstop=4 shiftwidth=4 autoindent

" 折叠
set foldmethod=syntax foldlevel=99

" 持久撤销 + 无备份
set nobackup noswapfile undofile
silent! call mkdir(&undodir, 'p')
set undodir=~/.vim/undo