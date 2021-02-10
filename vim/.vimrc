
" Reset autocommands if vimrc is parsed again
autocmd!

" Pathogen: Disable certain plugins
let g:pathogen_disabled = []
" Disable idris-vim because it sadly conflicts with idris2-vim
call add(g:pathogen_disabled, 'idris-vim')

" Load pathogen - https://github.com/tpope/vim-pathogen
runtime bundle/vim-pathogen/autoload/pathogen.vim
execute pathogen#infect()

" Enable syntax highlighting & filetype detection
syntax enable
filetype plugin indent on

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

" More visual modes (color status lines)
set laststatus=2
"if version >= 700
"    au InsertEnter * hi StatusLine term=reverse ctermbg=5 gui=undercurl guisp=Magenta
"    au InsertLeave * hi StatusLine term=reverse ctermbg=2 gui=bold,reverse
"endif

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

" Use unix line endings by default (windows)
set fileformats=unix,dos
set fileformat=unix

" Unfold everything (by default) - especially diffs
"" Disabled due to performance issues
" if &diff " only for diff mode/vimdiff
"     set diffopt=filler,context:1000000 " filler is default and inserts empty lines for sync
" endif

"au BufRead * normal zR     " -- doesn't seem to work
"set nofoldenable           " -- doesn't seem to work

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

" idris2-vim plugin configuration (indentation)
let g:idris_indent_if = 4
let g:idris_indent_case = 4
let g:idris_indent_let = 4
let g:idris_indent_rewrite = 8
let g:idris_indent_where = 4
let g:idris_indent_do = 4

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

" Open each file in a new tab if running on gvim
if has("gui_running")
    :au BufAdd,BufNewFile,BufRead * nested tab sball
end

" We use "," as the leader because "\\" is awful on german keyboard
let mapleader = ","

" Some plugins (idris) use the localleader instead, which we just set to the
" same key
let maplocalleader = ","

" Windows fix: Add ~/.vim at the front of the "runtimepath" to find plugins and syntax files
if has('win32') || has('win64')
    " Make windows use ~/.vim too, I don't want to use _vimfiles
    set runtimepath^=~/.vim
endif

" Visualize tabs and newlines
set listchars=tab:▸\ ,eol:¬
" Uncomment this to enable by default:
" set list " To enable by default
" Or use your leader key + l to toggle on/off
map <leader>l :set list!<CR>

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

