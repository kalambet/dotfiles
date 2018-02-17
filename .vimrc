"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Pathogen 
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
execute pathogen#infect()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General 
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Show line numbers
set number

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch 

" Don't redraw while executing macros (good performance config)
set lazyredraw 

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch 
" How many tenths of a second to blink when matching brackets
set mat=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Colors and Fonts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable syntax highlighting
syntax on

try
   color dracula 
catch
endtry


" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Text, tab and indent related
" """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" make backspace work like most other apps
set backspace=2 

" Use spaces instead of tabs
" set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 2 spaces
set shiftwidth=2
set tabstop=2

" Linebreak on 500 characters
set lbr
set tw=500

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugin settings 
" """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype plugin indent on

" CrelP plugin
set runtimepath^=~/.vim/bundle/ctrlp.vim

" Ack setup for ag
let g:ackprg = 'ag --vimgrep --smart-case'

" Airline
set laststatus=2
set ttimeoutlen=50
let g:airline_powerline_fonts = 0

" vim-go
set autowrite
let g:go_highlight_functions = 0 
let g:go_highlight_methods = 0 
let g:go_highlight_fields = 0
let g:go_highlight_types = 1
let g:go_highlight_operators = 0
let g:go_highlight_build_constraints = 0 

let g:go_fmt_command = "goimports"
let g:go_snippet_case_type = "camelcase"

let g:go_metalinter_autosave = 1
let g:go_metalinter_autosave_enabled = ['vet', 'golint']

let g:go_auto_sameids = 1

map <C-n> :cnext<CR>
map <C-m> :cprevious<CR>
nnoremap <leader>a :cclose<CR>

