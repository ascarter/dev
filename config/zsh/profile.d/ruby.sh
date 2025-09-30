export RBENV_ROOT="${XDG_DATA_HOME}/rbenv"
export RUBY_CONFIGURE_OPTS="--enable-yjit"

# Ruby shell configuration
if command -v rv >/dev/null 2>&1; then
  eval "$(rv shell init zsh)"
elif [ -d "${RBENV_ROOT}" ]; then
  eval "$(${RBENV_ROOT}/bin/rbenv init -)"
fi
