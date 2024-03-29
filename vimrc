" modeline {
" vim: set sw=4 ts=4 sts=4 et tw=78 foldmarker={,} foldlevel=0 foldmethod=marker spell:
"
" If you like some of these, please refer to github/spf13-vim
" as that distribution is a large base of this one,
" each piece added from the spf13 distro, once grok'd by me
" }

" functions {
  " ENV functions
  silent function! IsOsx()
    return has('macunix')
  endfunction

  silent function! IsUnix()
    return has('unix') && !has('macunix') && !has('win32unix')
  endfunction

  silent function! IsWin()
    return has('win16') || has('win32') || has('win64')
  endfunction

  function! InstallVundle()
    if !isdirectory("~/.vim/bundle/vundle")
      set shortmess+=filmnrxoOtT
      echo "Installing Vundle..."
      echo ""
      silent !git clone https://github.com/gmarik/vundle.git
        \ ~/.vim/bundle/vundle > /dev/null 2>&1
    endif
  endfunction

  function! UnBundle(arg, ...)
    let bundle = vundle#config#init_bundle(a:arg, a:000)
    call filter(g:bundles, 'v:val["name_spec"] != "' . a:arg . '"')
  endfunction

  com! -nargs=+         UnBundle
    \ call UnBundle(<args>)

  function! StripTrailingWhitespace()
    if !exists('g:keep_trailing_whitespace')
      " prep: save last search, and cursor position.
      let _s=@/
      let l = line(".")
      let c = col(".")
      " do the business:
      %s/\s\+$//e
      " clean up: restore previous search history, and cursor position
      let @/=_s
      call cursor(l, c)
    endif
  endfunction

  " return '[\s]' if trailing white space is detected
  " return '' otherwise
  function! StatuslineTrailingSpaceWarning()
    if !exists("b:statusline_trailing_space_warning")
      if !&modifiable
        let b:statusline_trailing_space_warning = ''
        return b:statusline_trailing_space_warning
      endif

      if search('\s\+$', 'nw') != 0
        let b:statusline_trailing_space_warning = '[\s]'
      else
        let b:statusline_trailing_space_warning = ''
      endif
    endif

    return b:statusline_trailing_space_warning
  endfunction

  " return the syntax highlight group under the cursor ''
  function! StatuslineCurrentHighlight()
    let name = synIDattr(synID(line('.'),col('.'),1),'name')

    if name == ''
      return ''
    else
      return '[' . name . ']'
    endif
  endfunction

  " return '[&et]' if &et is set wrong
  " return '[mixed-indenting]' if spaces and tabs are used to indent
  " return an empty string if everything is fine
  function! StatuslineTabWarning()
    if !exists("b:statusline_tab_warning")
      let b:statusline_tab_warning = ''

      if !&modifiable
        return b:statusline_tab_warning
      endif

      let tabs = search('^\t', 'nw') != 0

      " find spaces that arent used as alignment in the first indent column
      let spaces = search('^ \{' . &ts . ',}[^\t]', 'nw') != 0

      if (tabs && spaces)
        let b:statusline_tab_warning = '[mixed-indenting]'
      elseif (spaces && !&et) || (tabs && &et)
        let b:statusline_tab_warning = '[&et]'
      endif
    endif

    return b:statusline_tab_warning
  endfunction

  " return a warning for "long lines" where "long" is either &textwidth or 80
  " (if no &textwidth is set)
  "
  " return '' if no long lines
  " return '[#x,my,$z] if long lines are found, were x is the number of long
  " lines, y is the median length of the long lines and z is the length of the
  " longest line
  function! StatuslineLongLineWarning()
    if !exists("b:statusline_long_line_warning")
      if !&modifiable
        let b:statusline_long_line_warning = ''
        return b:statusline_long_line_warning
      endif

      let long_line_lens = s:LongLines()

      if len(long_line_lens) > 0
        let b:statusline_long_line_warning = "[" .
          \ '#' . len(long_line_lens) . "," .
          \ 'm' . s:Median(long_line_lens) . "," .
          \ '$' . max(long_line_lens) . "]"
      else
        let b:statusline_long_line_warning = ""
      endif
    endif

    return b:statusline_long_line_warning
  endfunction

  " return a list containing the lengths of the long lines in this buffer
  function! s:LongLines()
    let threshold = (&tw ? &tw : 80)
    let spaces = repeat(" ", &ts)
    let line_lens = map(getline(1,'$'), 'len(substitute(v:val, "\\t", spaces, "g"))')
    return filter(line_lens, 'v:val > threshold')
  endfunction

  " find the median of the given array of numbers
  function! s:Median(nums)
    let nums = sort(a:nums)
    let l = len(nums)

    if l % 2 == 1
      let i = (l-1) / 2
      return nums[i]
    else
      return (nums[l/2] + nums[(l/2)-1]) / 2
    endif
  endfunction

  " determine how tab functions should be used for insert mode mappings
  " inoremap <tab> <C-r>=s:InsertTabWrapper()<cr>
  " inoremap <S-tab> <C-n>
  function! s:InsertTabWrapper()
    let col = col(".") - 1
    if !col || getline(".")[col - 1] !~ "\k"
      return "\<tab>"
    else
      return "\<C-p>"
  endfunction
" }

" important {
  set nocompatible                " first line to be iMproved
  set pastetoggle=<F2>            " pastetoggle (sane indentation on paste)

  " allow for user customization before vimrc sourced
  if filereadable(expand("~/.vimrc.before"))
    source ~/.vimrc.before
  endif

  if !IsWin()
    set shell=/bin/sh
  endif

  " on Windows, also use '.vim' instead of 'vimfiles';
  " this makes synchronization across (heterogeneous) systems easier
  if IsWin()
    set rtp=$HOME/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,$HOME/.vim/after
  endif

  " change mapleader <leader> to comma, but retain default for local buffers
  " setting here causes this to be set for any <leader> references later
  " in the initialization sequence
  if !exists("g:no_leader_change")
    let mapleader = ","
    let maplocalleader = "\\"
  endif

  scriptencoding utf-8            " default to utf-8

  " setup vundle
  silent call InstallVundle()     " install vundle
  source ~/.vim/vundles.vim
" }

" moving around, searching and patterns {
  set whichwrap=b,s,h,l,<,>,[,]   " which cmnds wrap to another line
  set incsearch                   " incremental search
  set ignorecase                  " case insensitive search matching
  set smartcase                   " no ignore if pattern has upper-case characters
" }

" tags {
" }

" displaying text {
  set scrolljump=5                " lines to scroll when cursor leaves screen
  set scrolloff=3                 " # of screen lines to show around cursor
  set nowrap                      " do not wrap long lines
  set linebreak                   " wrap long lines in 'breakat' (not a hard break)
  set showbreak=↪\                " placed before wrapped screen lines
  if (&termencoding ==# "utf-8" || &encoding ==# "utf-8")
    let &showbreak = "\u21aa "
  endif
  set sidescrolloff=2             " min # cols to keep left/right of cursor
  set display+=lastline           " show last line, even if it doesn't fit
  set cmdheight=1                 " # of lined for the cli
  if (&listchars ==# "eol:$")     " strings used for list mode
    set listchars=tab:→\ ,trail:▸
    if (&termencoding ==# "utf-8" || &encoding ==# "utf-8")
      let &showbreak = "\u21aa "
      let &listchars = "tab:\u2192 ,trail:\u25b8"
    endif
  endif
  set number                      " show line #
  set norelativenumber            " do not show relative line #
  set numberwidth=1               " # cols for line #
" }

" syntax, highlighting and spelling {
  if has("autocmd")
    " turn on ft detection, plugins and indent
    filetype plugin indent on
  endif

  if has("syntax") && !exists("g:syntax_on")
    syntax enable                 " turn on syntax highlighting
  endif

  set synmaxcol=2048              " no need to syntax color super long lines
  set hlsearch                    " highlights matched search pattern
  set cursorline                  " highlight screen line of cursor

  if exists('&colorcolumn')
    set colorcolumn=80            " highlight column at #
  else
    au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>80v.\+', -1)
  endif

  " toggle spelling mistakes
  map <F7> :setlocal spell! spell?<CR>
  highlight SpellErrors guibg=red guifg=black ctermbg=red ctermfg=black
" }

" multiple windows {
  set laststatus=2                " show status line even if only 1 window

  " statusline configured in after/plugin/statusline.vim

  "set helpheight=30               " initial height of help window
  set hidden                      " keep buffer when no longer shown
" }

" multiple tab pages {
" }

" terminal {
  set ttyfast                     " term connection is fast
  " set up gui cursor to look nice
  set guicursor=n-v-c:block-Cursor-blinkon0,ve:ver35-Cursor,o:hor50-Cursor,i-ci:ver25-Cursor,r-cr:hor20-Cursor,sm:block-Cursor-blinkwait175-blinkoff150-blinkon175
" }

" using the mouse {
  if has("mouse")
    set mouse=a                   " list of flags for using the mouse
  endif
  set mousehide                   " hide mouse on insert mode
" }

" GUI (here instead of .gvimrc) {
  if has("gui_running")
    set lines=40 columns=117

    set guioptions-=m			" remove the menu
    set guioptions-=T			" remove the toolbar
    set guioptions-=t			" remove tear-off menus
    set guioptions+=a     " visual mode is global
    set guioptions+=c			" use :ex command-mode prompt instead of modal dialogs

    if has("gui_macvim")
      " make Mac 'Option' key behave as 'Alt'
      set mmta

      set guifont="Source Code Pro 16, Menlo Regular 14"
      set linespace=2			" # pixel lines between characters

      " MacVIM shift+arrow-keys behavior (required in .vimrc)
      let macvim_hig_shift_movement = 1
    elseif has("unix")
      set guifont="DejaVu Sans Mono 12"
    elseif has("win32")
      set guifont="Consolas:h13"
    endif

    set transparency=5			" transparency of text bg as %
    "set fullscreen				" run in fullscreen mode

    " setting these in GVim/MacVim because terminals cannot distinguish between
    " <space> and <S-space> because curses sees them the same
    nnoremap <space> <PageDown>
    nnoremap <S-space> <PageUp>

    if has("autocmd")
      " auto resize splits when window resizes
      "autocmd VimResized * wincdm =
    endif
  elseif &term == "xterm" || &term == "screen"
    set t_Co=256             " enable 256 colors for CSApprox warning
  endif
" }

" printing {
  set printoptions=header:0,duplex:long,paper:letter
" }

" messages and info {
  set shortmess+=filmnrxoOtT      " abbr. of messages (avoids "hit enter")
  set showcmd                     " show partial cmd keys in status bar
  set ruler                       " show cursor position below window
  " ruler on steroids?
  set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%)
  set visualbell                  " use visual bell instead of beep
" }

" selecting text {
  if has("x") && has("gui")
    set clipboard=unnamedplus     " on linux, use + register for copy/paste
  elseif has('gui')
    set clipboard=unnamed         " on mac/win, use * register for copy/paste
  else
    set clipboard=unnamed         " use system clipboard
  endif
" }

" editing text {
  set backspace=indent,eol,start  " backspace over everything
  if (v:version > 703)
    " delete comment char on 2nd line when joining commented lines
    set formatoptions+=j
  endif
  "set completeopt+=longest        " better omni-complete menu
  set completeopt=menu,preview,longest
  set showmatch                   " when inserting bracket, brief jump to match
  set nojoinspaces                " do not add second space when joining lines
" }

" tabs and indenting {
  set tabstop=4                   " # spaces <Tab> equals
  set shiftwidth=4                " # spaces used for each (auto)indent
  set smarttab                    " <Tab> in indent inserts 'shiftwidth' spaces
  set shiftround                  " round to 'shiftwidth' for "<<" and ">>"
" }

" folding {
  if has("folding")
    set foldenable                " display all folds open
    set foldmethod=marker         " folding type
  endif
" }

" diff mode {
" }

" mapping {
" }

" reading and writing files {
  set nobackup                    " do not keep a backup ~ file
  set backupdir=~/.vim/.backup,.  " list of dirs for backup file
  set autoread                    " auto read file modified outside of vim
" }

" the swap file {
  set noswapfile                  " do not use a swap file
  set directory=~/.vim/.backup,~/tmp,. " list of dirs for swap files
" }

" command line editing {
  set history=500                 " save # cmds in history
  set wildmode=list:longest,full  " how cmd line completion works

  " file name completion ignores
  set wildignore+=*.exe,*.swp,.DS_Store

  " prevent term vim error
  if exists("&wildignorecase")
    set wildignorecase            " ignore case when completing file names
  endif
  set wildmenu                    " cmd line completion shows list of matches

  " persistent undo
  if has("persistent_undo")
    set undofile
    set undodir=~/.vim/.backup/undo,~/tmp,.
  endif
" }

" executing external commands {
  set shell=$SHELL                " shell to use for ext cmds
" }

" running make and jumping to errors {
" }

" language specific {
" }

" multi-byte characters {
  set encoding=utf-8              " character encoding
" }

" various {
  set virtualedit=onemore         " allow for cursor beyond last char
  " better unix/win compatibility
  set viewoptions=folds,options,cursor,unix,slash
  if !exists('g:no_views')
    " Add exclusions to mkview and loadview
    " eg: *.*, svn-commit.tmp
    let g:skipview_files = [
      \ '\[example pattern\]' ]
  endif
  " Ctags {
    set tags=./tags;/,~/.vimtags
  " }
" }

" Autocmd {
  if has("autocmd")
    " recalculate the trailing whitespace warning when idle, and after saving
    autocmd cursorhold,bufwritepost * unlet! b:statusline_trailing_space_warning

    " recalculate the tab warning flag when idle and after writing
    autocmd cursorhold,bufwritepost * unlet! b:statusline_tab_warning

    "recalculate the long line warning when idle and after saving
    autocmd cursorhold,bufwritepost * unlet! b:statusline_long_line_warning

    " automatically switch to the current file directory when a new
    " buffer is opened; to prevent this behavior, add the following to
    " your .vimrc.before
    "   let g:no_autochdir = 1
    if !exists("g:no_autochdir")
      autocmd BufEnter * if bufname("") !~ "^\[A-Za-z0-9\]*://" | lcd %:p:h | endif
    endif

    " remember last position in file
    autocmd BufReadPost *
      \ if line("'\"") > 0 && line("'\"") <= line("$") |
      \   exe "normal g`\"" |
      \ endif

    " Instead of reverting the cursor to the last position in the buffer,
    " we set it to the first line when editing a git commit message
    autocmd FileType gitcommit
      \ autocmd! BufEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0])

    " remove trailing whitespace and ^M chars
    autocmd FileType c,cpp,java,go,php,javascript,python,twig,xml,yml
      \ autocmd BufWritePre <buffer> call StripTrailingWhitespace()

    " format go docs on load
    autocmd FileType go autocmd BufWritePre <buffer> Fmt

    " set filetype for twig
    autocmd BufNewFile,BufRead *.html.twig set filetype=html.twig

    " best in a plugin but here for now
    autocmd FileType haskell setlocal expandtab shiftwidth=2 softtabstop=2

    " set coffeescript filetype, just in case
    autocmd BufNewFile,BufRead *.coffee set filetype=coffee

    " Workaround vim-commentary for Haskell
    autocmd FileType haskell setlocal commentstring=--\ %s
    " Workaround broken colour highlighting in Haskell
    autocmd FileType haskell setlocal nospell

    " auto resize window splits
    autocmd VimResized * exe "normal! \<C-w>="
  endif
" }

" Colors {
  if empty($ITERM_PROFILE)
    set background=dark
    if filereadable(expand("~/.vim/bundle/vim-colors-solarized/colors/solarized.vim"))
      let g:solarized_termcolors=256
      let g:solarized_termtrans = 1
      let g:solarized_contrast = "high"
      let g:solarized_visibility = "high"
      colorscheme solarized
    endif
    if filereadable(expand("~/.vim/bundle/base16-vim/colors/base16-default.vim"))
      colorscheme base16-default
    endif
  else
    " csapprox can look silly on iterm, do not load it
    let g:CSApprox_loaded = 1
    colorscheme $ITERM_PROFILE
  endif
" }

" allow for user customization after vimrc sourced
if filereadable(expand("~/.vimrc.after"))
  source ~/.vimrc.after
endif
