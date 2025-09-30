# Non-interactive shell configuration:
# zshenv ➜ zprofile
#
# Interactive shell configuration:
# zshenv ➜ zprofile ➜ zshrc ➜ zlogin ➜ zlogout

# =====================================
# Completion system
# =====================================

# Add homebrew completion locations
if command -v brew >/dev/null 2>&1; then
  rustup_prefix=$(brew --prefix rustup 2>/dev/null)
  [[ -d "$rustup_prefix/share/zsh/site-functions" ]] && fpath+=("$rustup_prefix/share/zsh/site-functions")
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
# Key bindings & Vi Mode
# =====================================

# Enable vim mode
bindkey -v

# Enable edit command line using $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line

# Bind `v` to edit the command line in the editor
bindkey -M vicmd 'v' edit-command-line

# Better vim mode experience
# Reduce delay when switching modes
export KEYTIMEOUT=1

# Change cursor shape according to vi mode
# Don't run when in Ghostty since it already supports this.
if [[ "$TERM" != *ghostty* && "$GHOSTTY_SHELL_INTEGRATION_NO_CURSOR" != 1 ]]; then
  # Change the cursor shape according to the current vi mode.
  _vi_cursor_mode() {
    case ${KEYMAP-} in
      vicmd|visual)  print -Pn "\e[1 q" ;;  # Block cursor
      *)             print -Pn "\e[5 q" ;;  # Beam cursor
    esac
  }

  # Bind cursor mode function to appropriate ZLE hooks
  zle-line-init() { _vi_cursor_mode }
  zle-keymap-select() { _vi_cursor_mode }

  # Register functions as ZLE widgets
  zle -N zle-line-init
  zle -N zle-keymap-select

  # Reset cursor before executing commands
  _vi_preexec_reset_cursor() {
    print -Pn "\e[0 q"
  }
  add-zsh-hook preexec _vi_preexec_reset_cursor
fi

# Add useful vi-mode key bindings
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word

# =====================================
# Load rc modules
# =====================================
if [[ -d "${ZDOTDIR}/rc.d" ]]; then
  for rc in "${ZDOTDIR}"/rc.d/*.sh(N); do
    source "$rc"
  done
  unset rc
fi
