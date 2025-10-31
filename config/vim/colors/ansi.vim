" ====================================================================
" ANSI 16‑color theme for Vim & Neovim
" ====================================================================

" ANSI 16 color scheme that inherits colors from terminal
"
" Palette:
" ================================================
" 0: Black        │   8: Bright Black (dark gray)
" 1: Red          │   9: Bright Red
" 2: Green        │  10: Bright Green
" 3: Yellow       │  11: Bright Yellow
" 4: Blue         │  12: Bright Blue
" 5: Magenta      │  13: Bright Magenta
" 6: Cyan         │  14: Bright Cyan
" 7: White (gray) │  15: Bright White
" ================================================

hi clear
set t_Co=16
set background=dark
hi Comment ctermfg=8 cterm=italic
hi String ctermfg=4
hi Constant ctermfg=3 cterm=bold
hi Number ctermfg=5 cterm=bold
hi Boolean ctermfg=3 cterm=bold
hi Keyword ctermfg=4 cterm=bold
hi Statement ctermfg=4 cterm=bold
hi Conditional ctermfg=4 cterm=bold
hi Repeat ctermfg=4 cterm=bold
hi Operator ctermfg=4 cterm=bold
hi Function ctermfg=NONE cterm=bold
hi Type ctermfg=6
hi Structure ctermfg=6
hi StorageClass ctermfg=6
hi Identifier ctermfg=NONE
hi DiagnosticUnderlineError cterm=underline ctermfg=NONE
hi DiagnosticUnderlineWarn  cterm=underline ctermfg=NONE
hi DiagnosticUnderlineInfo  cterm=underline ctermfg=NONE
hi DiagnosticUnderlineHint  cterm=underline ctermfg=NONE
hi diffAdded   ctermfg=NONE
hi diffRemoved ctermfg=1
hi diffChanged ctermfg=NONE
hi DiffAdd    ctermfg=0  ctermbg=10 cterm=bold
hi DiffDelete ctermfg=15 ctermbg=9  cterm=bold
hi DiffChange ctermfg=0  ctermbg=12
hi DiffText   ctermfg=0  ctermbg=14 cterm=bold,italic
hi StatusLine   ctermfg=NONE ctermbg=NONE cterm=bold
hi StatusLineNC ctermfg=8 cterm=NONE
hi Pmenu        ctermfg=NONE ctermbg=NONE
hi PmenuSel     ctermfg=15 ctermbg=4 cterm=bold
hi MatchParen   ctermfg=0 ctermbg=3 cterm=bold
hi LineNr       ctermfg=8
hi CursorLineNr ctermfg=NONE ctermbg=NONE cterm=bold
hi Visual ctermfg=12 ctermbg=NONE cterm=reverse
hi Search ctermfg=11 ctermbg=NONE cterm=reverse
hi IncSearch ctermfg=11 ctermbg=NONE cterm=reverse
