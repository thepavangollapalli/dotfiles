" ============================================================================
" ~/.vimrc — managed by ~/code/dotfiles
" ============================================================================

set nocompatible
scriptencoding utf-8
let mapleader = ','
let maplocalleader = ','

" Plugins --------------------------------------------------------------------
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

if filereadable(expand('~/.vim/autoload/plug.vim'))
  call plug#begin('~/.vim/plugged')
    Plug 'tpope/vim-fugitive'
    Plug 'tpope/vim-repeat'
    Plug 'tpope/vim-surround'
    Plug 'junegunn/seoul256.vim'
    Plug 'junegunn/fzf.vim'
  call plug#end()
endif

" General --------------------------------------------------------------------
filetype plugin indent on
syntax enable
set encoding=utf-8
set mouse=a
set clipboard=unnamed
set backspace=indent,eol,start
set history=1000
set autoread
set shortmess+=I
set updatetime=300

" UI -------------------------------------------------------------------------
set number numberwidth=5
set ruler
set showcmd
set laststatus=2
set showmatch
set splitbelow splitright
set wildmenu
set wildmode=longest:full,full
set signcolumn=yes
set scrolloff=3
set diffopt+=vertical
set fillchars+=vert:│

" Search ---------------------------------------------------------------------
set incsearch
set hlsearch
set ignorecase smartcase

" Editing --------------------------------------------------------------------
set tabstop=2 shiftwidth=2 softtabstop=2 expandtab shiftround
set autoindent
set nojoinspaces
set gdefault
set listchars=tab:»·,trail:·,nbsp:·
set wrap linebreak breakindent

" Files ----------------------------------------------------------------------
let s:vimdir = expand('~/.vim')
for s:dir in ['tmp', 'undo']
  if !isdirectory(s:vimdir . '/' . s:dir)
    call mkdir(s:vimdir . '/' . s:dir, 'p')
  endif
endfor
let &backupdir = s:vimdir . '/tmp'
let &directory = s:vimdir . '/tmp'
let &undodir   = s:vimdir . '/undo'
set backup
set undofile

" Colors ---------------------------------------------------------------------
if has('termguicolors')
  set termguicolors
endif
set background=dark
silent! colorscheme seoul256

" Status line ----------------------------------------------------------------
function! StatuslineGit() abort
  if exists('*FugitiveHead')
    let l:branch = FugitiveHead()
    return empty(l:branch) ? '' : ' ' . l:branch
  endif
  return ''
endfunction
set statusline=%<%f%{StatuslineGit()}\ %h%m%r%=%{&filetype}\ %l:%c\ %p%%

" Mappings -------------------------------------------------------------------
inoremap kj <Esc>
nnoremap <leader>w :write<CR>
nnoremap <leader>h :nohlsearch<CR>
nnoremap <leader><leader> <C-^>
nnoremap <leader>f :Files<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>g :Ag<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Autocommands ---------------------------------------------------------------
augroup vimrc
  autocmd!
  autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line("$") |
        \   execute "normal! g`\"" |
        \ endif
  autocmd FileType * setlocal formatoptions-=cro
  autocmd BufEnter,FocusGained * checktime
augroup END
