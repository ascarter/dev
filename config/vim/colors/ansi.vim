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

if exists("syntax_on")
  syntax reset
endif

hi clear

let g:colors_name = "ansi"

" Force use of terminal ANSI colors
set notermguicolors

" =====================================
" UI ELEMENTS
" =====================================
" Current line / column
hi CursorLine   ctermfg=NONE ctermbg=NONE cterm=NONE
hi CursorColumn ctermfg=NONE ctermbg=NONE cterm=NONE

" Line numbers
hi CursorLineNr ctermfg=NONE  ctermbg=NONE   cterm=bold
hi LineNr       ctermfg=Gray

" Status line
hi StatusLine   ctermfg=NONE   ctermbg=NONE   cterm=bold
hi StatusLineNC ctermfg=8 cterm=NONE

" Modes
hi ModeInsert ctermfg=0  ctermbg=11 cterm=bold
hi ModeVisual ctermfg=15 ctermbg=12 cterm=bold

" Popup menus
hi Pmenu      ctermfg=NONE ctermbg=NONE cterm=NONE
hi PmenuSel   ctermfg=15   ctermbg=4    cterm=bold
hi PmenuSbar  ctermfg=4    ctermbg=8
hi PmenuThumb ctermfg=NONE ctermbg=7

" Visual selection
hi Visual ctermfg=12 ctermbg=NONE cterm=reverse

" Incremental search / highlight
hi Search ctermfg=11 ctermbg=NONE cterm=reverse
hi IncSearch ctermfg=11 ctermbg=NONE cterm=reverse

" Bracket match (cursor.match)
hi MatchParen ctermfg=12 ctermbg=NONE cterm=bold,reverse

" Gutter/sign column
hi SignColumn ctermfg=7 ctermbg=NONE

" Debug (breakpoints, etc.)
hi DebugBreakpoint ctermfg=1 cterm=bold
hi DebugPC         ctermfg=3 cterm=bold

" Messages
hi WarningMsg ctermfg=8  ctermbg=11
hi ErrorMsg   ctermfg=15 ctermbg=1  cterm=bold,italic

" =====================================
" SYNTAX HIGHLIGHTING
" =====================================
hi Boolean      ctermfg=NONE
hi Comment      ctermfg=7    cterm=italic
hi Conditional  ctermfg=NONE
hi Constant     ctermfg=3    cterm=bold
hi Number       ctermfg=3    cterm=bold
hi Exception    ctermfg=NONE
hi Function     ctermfg=NONE cterm=bold
hi Identifier   ctermfg=NONE cterm=italic
hi Include      ctermfg=NONE
hi Keyword      ctermfg=4    cterm=bold
hi Label        ctermfg=NONE
hi Macro        ctermfg=NONE cterm=italic
hi Operator     ctermfg=NONE
hi PreProc      ctermfg=NONE cterm=italic
hi Repeat       ctermfg=NONE
hi Special      ctermfg=NONE
hi Statement    ctermfg=4
hi StorageClass ctermfg=NONE
hi String       ctermfg=2
hi Structure    ctermfg=6    cterm=bold
hi Tag          ctermfg=4
hi Type         ctermfg=6
hi Whitespace   ctermfg=8

hi Error ctermfg=1 ctermbg=NONE
hi Todo  ctermfg=2 ctermbg=NONE cterm=bold,italic

" =====================================
" DIFF
" =====================================
hi DiffAdd    ctermfg=0  ctermbg=10 cterm=bold
hi DiffChange ctermfg=0  ctermbg=12
hi DiffDelete ctermfg=15 ctermbg=9  cterm=bold
hi DiffText   ctermfg=0  ctermbg=14 cterm=bold,italic

" Gutter-only diff markers
hi diffAdded   ctermfg=2
hi diffRemoved ctermfg=1
hi diffChanged ctermfg=6

" =====================================
" DIAGNOSTICS (Neovim-only undercurl)
" =====================================
if has("nvim")
  hi DiagnosticUnderlineError cterm=undercurl ctermfg=1
  hi DiagnosticUnderlineWarn  cterm=undercurl ctermfg=11
  hi DiagnosticUnderlineInfo  cterm=undercurl ctermfg=14
  hi DiagnosticUnderlineHint  cterm=undercurl ctermfg=15
endif
