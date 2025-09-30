# Defauls:
#   macOS:  PS1="%n@%m %1~ %#"
#   Fedora: PS1="[%n@%m]%~%#"
#   Ubuntu: PS1="%m%#"

prompt_opts=(cr percent subst)
autoload -Uz vcs_info
autoload -Uz add-zsh-hook
add-zsh-hook precmd vcs_info
zstyle ':vcs_info:git:*' formats '%b'
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes false
setopt prompt_subst

DIM_ON="%{$(echo -e '\e[2m')%}"
DIM_OFF="%{$(echo -e '\e[22m')%}"
ITALIC_ON="%{$(echo -e '\e[3m')%}"
ITALIC_OFF="%{$(echo -e '\e[23m')%}"

# Build prompt conditionally (two lines with blank line above)
PROMPT=$'\n'
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  PROMPT="${PROMPT}${DIM_ON}%n@%m${DIM_OFF}:"
fi
PROMPT="${PROMPT}%B%3~%b${DIM_ON}${ITALIC_ON}"'${vcs_info_msg_0_:+ ($vcs_info_msg_0_)}'${ITALIC_OFF}${DIM_OFF}$'\n''%# '

# Set grep colors on macOS
# Bold (1) and italic (3) with default foreground color (39)
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;3;39'

# ls
# directories (di) bold (1)  default FG (39)
# symlink (ln)     italic(3) default FG (39)
# executable (ex)  dim (2)   default FG (39)
export LS_COLORS='di=1;39:ln=3;39:ex=2;39'
