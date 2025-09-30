#!/bin/sh

# Python toolchain management via uv

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_BIN_HOME=${XDG_BIN_HOME:-${XDG_DATA_HOME}/../bin}
UV_HOME="${UV_HOME:-${XDG_DATA_HOME}/uv}"
UV_TOOL_DIR="${UV_TOOL_DIR:-${UV_HOME}/tools}"
UV_TOOL_BIN_DIR="${UV_TOOL_BIN_DIR:-${UV_HOME}/bin}"

log() {
  if [ "$#" -eq 1 ]; then
    printf "%s\n" "$1"
  elif [ "$#" -gt 1 ]; then
    printf "$(tput bold)%-10s$(tput sgr0)\t%s\n" "$1" "$2"
  fi
}

install() {
  # Check if uv is already installed
  if command -v uv >/dev/null 2>&1; then
    log "python" "uv already installed, skipping"
    status
    return 0
  fi

  log "python" "installing uv"

  # Create our custom tool directories
  mkdir -p "${UV_TOOL_DIR}" "${UV_TOOL_BIN_DIR}"

  # Install uv via the official script with no path modification
  curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh

  log "python" "uv installed successfully"
}

update() {
  if ! command -v uv >/dev/null 2>&1; then
    log "python" "uv not installed"
    return 1
  fi

  log "python" "updating uv"
  uv self update
}

uninstall() {
  if command -v uv >/dev/null 2>&1 || [ -d "${UV_HOME}" ]; then
    log "python" "removing uv installation"

    # Remove uv binaries from .local/bin
    if [ -f "${XDG_BIN_HOME}/uv" ]; then
      rm -f "${XDG_BIN_HOME}/uv" "${XDG_BIN_HOME}/uvx"
    fi

    # Remove UV_HOME directory (contains tools and data)
    if [ -d "${UV_HOME}" ]; then
      rm -rf "${UV_HOME}"
    fi
  else
    log "python" "uv already uninstalled"
  fi
}

status() {
  if command -v uv >/dev/null 2>&1; then
    local current_version
    current_version=$(uv --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
    log "python" "uv installed, version: ${current_version}"
  else
    log "python" "uv not installed"
  fi
}

# Handle command line arguments
action="${1:-status}"
case "${action}" in
install | update | uninstall | status)
  "${action}"
  ;;
*)
  echo "Usage: $0 {install|update|uninstall|status}" >&2
  exit 1
  ;;
esac
