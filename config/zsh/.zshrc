# Non-interactive shell configuration:
# zshenv ➜ zprofile
#
# Interactive shell configuration:
# zshenv ➜ zprofile ➜ zshrc ➜ zlogin ➜ zlogout

# =====================================
# Completion system
# =====================================

# Add dev completions directory
if [[ -d "${XDG_DATA_HOME}/zsh/completions" ]]; then
  fpath=("${XDG_DATA_HOME}/zsh/completions" $fpath)
fi

# Enable advanced tab completion
autoload -Uz compinit
compinit -u

# Load colors
autoload -Uz colors
colors

# Load hook system
autoload -Uz add-zsh-hook

# Enable bash compatibility
autoload -Uz bashcompinit
bashcompinit

# =====================================
# man pages
# =====================================

# Add XDG_DATA_HOME/man to MANPATH for tools that install man pages locally
if [[ -d "${XDG_DATA_HOME}/man" ]]; then
  export MANPATH="${XDG_DATA_HOME}/man:${MANPATH}"
fi

# =====================================
# ZSH Options
# =====================================

# Allow changing directories without typing cd
setopt AUTO_CD

# Push the old directory onto the stack on cd
setopt AUTO_PUSHD

# Do not store duplicates in the stack
setopt PUSHD_IGNORE_DUPS

# Do not print directory stack after pushd/popd
setopt PUSHD_SILENT

# Enable completion for aliases
setopt COMPLETE_ALIASES

# Move cursor to end of word on completion
setopt ALWAYS_TO_END

# Allow completion from middle of word
setopt COMPLETE_IN_WORD

# Expansion and globbing
setopt EXTENDED_GLOB

# Include hidden files in globbing
setopt GLOB_DOTS

# History size configuration
HISTSIZE=10000
SAVEHIST=10000

# Share history between sessions
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

# Show command before executing history command
setopt HIST_VERIFY

# Ask for confirmation for `rm *' or `rm path/*'
setopt RM_STAR_WAIT

# =====================================
# Completion configuration
# =====================================

# Automatically rehash command list when new executables are added
zstyle ':completion:*' rehash true

# Cache completion for performance
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Completion behavior
zstyle ':completion:*' completer _extensions _complete _approximate
zstyle ':completion:*' menu select
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order alias builtins functions commands
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' file-list all

# Fuzzy matching for completion
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# =====================================
# Key bindings (Emacs mode with Vim-inspired enhancements)
# =====================================

# Enable Emacs editing mode
bindkey -e

# Edit command line in $EDITOR (Helix/Zed)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line        # Ctrl-X Ctrl-E to open current line in $EDITOR

# Vim-like movement on Meta-h/j/k/l (useful on HHKB without arrows)
bindkey '^[h' backward-char
bindkey '^[l' forward-char
bindkey '^[j' down-line-or-history
bindkey '^[k' up-line-or-history

# Explicit standard movements/history (some already default)
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# Word motions (Meta-b/f are default; declare for clarity)
bindkey '^[b' backward-word
bindkey '^[f' forward-word

# Deletions / kills
bindkey '^W' backward-kill-word         # kill previous word
bindkey '^[d' kill-word                 # Meta-d kill next word
bindkey '^K' kill-line                  # kill to end of line
bindkey '^U' backward-kill-line         # kill to start of line
bindkey '^[t' transpose-words           # swap adjacent words

# Yank enhancements
bindkey '^[y' yank                      # Meta-y also yanks (Ctrl-Y is default)

# Backspace variations
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char

# =====================================
# Load rc modules
# =====================================
if [[ -d "${ZDOTDIR}/rc.d" ]]; then
  for rc in "${ZDOTDIR}"/rc.d/*.sh(N); do
    source "$rc"
  done
  unset rc
fi
