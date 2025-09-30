export UV_HOME="${XDG_DATA_HOME}/uv"
export UV_TOOL_DIR="${UV_HOME}/tools"
export UV_TOOL_BIN_DIR="${UV_HOME}/bin"

# Add uv tool bin directory to PATH
if command -v uv >/dev/null 2>&1; then
  if [ -d "${UV_TOOL_BIN_DIR}" ]; then
    export PATH="${UV_TOOL_BIN_DIR}:${PATH}"
  fi
  eval "$(uv generate-shell-completion zsh)"
fi
