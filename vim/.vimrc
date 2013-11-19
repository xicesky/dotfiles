
" Reset autocommands if vimrc is parsed again
autocmd!

"colorscheme desert

" Load local settings
runtime! local/colorscheme.vim
runtime! local/gui.vim

set nocompatible
set backspace=indent,eol,start
set background=dark

" For gvim

"set textwidth=0
"set ruler
set number

set showcmd
set showmatch
set incsearch
set hlsearch
set nowrap
syntax enable

" More visual modes (color status lines)
set laststatus=2
"if version >= 700
"    au InsertEnter * hi StatusLine term=reverse ctermbg=5 gui=undercurl guisp=Magenta
"    au InsertLeave * hi StatusLine term=reverse ctermbg=2 gui=bold,reverse
"endif

" Enable filetype plugin
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from the outside
set autoread

" Set backspace config
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Ignore case when searching
set ignorecase
set smartcase

" Tabs and stuff by sky
set autoindent
set shiftwidth=4
set expandtab
set tabstop=4

" In diff mode unfold all
if &diff " only for diff mode/vimdiff
    set diffopt=filler,context:1000000 " filler is default and inserts empty lines for sync
endif

" Vim :Ex configuration
set splitright
" v opens a window on the right not on the left
let g:netrw_altv = 1

" gnupg.vim plugin configuration
let g:GPGUseAgent = 1
let g:GPGPreferSymmetric = 0
let g:GPGPreferArmor = 0
let g:GPGPreferSign = 1
let g:GPGUsePipes = 0

" Mega-Auto-Indent paste
":nnoremap <F2> "+P=']
":inoremap <F2> <C-o>"+P<C-o>=']

" Toggle line numbers
nmap <F3> :set invnumber<CR>

" Paste mode
nnoremap <F4> :set invpaste paste?<CR>
set pastetoggle=<F4>
set showmode

" Sky's close tab shortcut
" <C-w> (breaks split-window navigation...)
" map <C-w> :bw<CR>
map <C-x> :bw<CR>

" We use "," as the leader because "\\" is awful on german keyboard
let mapleader = ","

" Using vimdiff for 3-way merges: http://blog.binchen.org/?p=601
" if you know the buffer number, you can use hot key like “,2″ (press comma
" first, then press two key as quickly as possible) to pull change from buffer
" number 2
map <silent> <leader>2 :diffget 2<CR> :diffupdate<CR>
map <silent> <leader>3 :diffget 3<CR> :diffupdate<CR>
map <silent> <leader>4 :diffget 4<CR> :diffupdate<CR>

" To have the numeric keypad working with putty / vim
imap <Esc>Oq 1
imap <Esc>Or 2
imap <Esc>Os 3
imap <Esc>Ot 4
imap <Esc>Ou 5
imap <Esc>Ov 6
imap <Esc>Ow 7
imap <Esc>Ox 8
imap <Esc>Oy 9
imap <Esc>Op 0
imap <Esc>On .
imap <Esc>OQ /
imap <Esc>OR *
imap <Esc>Ol +
imap <Esc>OS -

