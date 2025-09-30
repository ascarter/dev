#!/bin/sh

# Node.js toolchain management via fnm

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_BIN_HOME=${XDG_BIN_HOME:-${XDG_DATA_HOME}/../bin}
FNM_DIR="${FNM_DIR:-${XDG_DATA_HOME}/fnm}"

log() {
  if [ "$#" -eq 1 ]; then
    printf "%s\n" "$1"
  elif [ "$#" -gt 1 ]; then
    printf "$(tput bold)%-10s$(tput sgr0)\t%s\n" "$1" "$2"
  fi
}

install() {
  # Check if fnm is already installed
  if [ -d "${FNM_DIR}" ] && [ -x "${FNM_DIR}/fnm" ]; then
    log "nodejs" "fnm already installed, skipping"
    status
    return 0
  fi

  log "nodejs" "installing fnm to ${FNM_DIR}"

  # Detect OS
  local os
  case "$(uname -s)" in
  Linux*) os="linux" ;;
  Darwin*) os="macos" ;;
  *)
    log "nodejs" "unsupported OS: $(uname -s)"
    return 1
    ;;
  esac

  # Check dependencies
  if ! command -v curl >/dev/null 2>&1; then
    log "nodejs" "curl is required for installation"
    return 1
  fi

  if ! command -v unzip >/dev/null 2>&1; then
    log "nodejs" "unzip is required for installation"
    return 1
  fi

  # Get latest version
  local version
  version=$(curl -s https://api.github.com/repos/Schniz/fnm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
  if [ -z "$version" ]; then
    log "nodejs" "failed to fetch latest fnm version"
    return 1
  fi

  local filename="fnm-${os}.zip"
  local url="https://github.com/Schniz/fnm/releases/download/${version}/${filename}"

  log "nodejs" "downloading and extracting fnm ${version}"
  mkdir -p "${FNM_DIR}"
  if ! curl -fsSL "$url" | unzip -q - -d "${FNM_DIR}"; then
    log "nodejs" "failed to download or extract fnm"
    return 1
  fi

  chmod +x "${FNM_DIR}/fnm"

  log "nodejs" "fnm installed successfully"
}

update() {
  if ! [ -d "${FNM_DIR}" ] || ! [ -x "${FNM_DIR}/fnm" ]; then
    log "nodejs" "fnm not installed"
    return 1
  fi

  log "nodejs" "updating fnm"
  # fnm doesn't have built-in self-update, so reinstall
  install
}

uninstall() {
  if [ -d "${FNM_DIR}" ] || command -v fnm >/dev/null 2>&1; then
    log "nodejs" "removing fnm installation"

    # Remove FNM directory
    if [ -d "${FNM_DIR}" ]; then
      rm -rf "${FNM_DIR}"
    fi
  else
    log "nodejs" "fnm already uninstalled"
  fi
}

status() {
  if [ -d "${FNM_DIR}" ] && [ -x "${FNM_DIR}/fnm" ]; then
    local fnm_version node_version
    fnm_version=$("${FNM_DIR}/fnm" --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")

    # Check if Node.js is available via fnm
    if command -v node >/dev/null 2>&1; then
      node_version=$(node --version 2>/dev/null | sed 's/^v//' || echo "none")
      log "nodejs" "fnm installed (v${fnm_version}), Node.js: ${node_version}"
    else
      log "nodejs" "fnm installed (v${fnm_version}), Node.js: not installed"
    fi
  else
    log "nodejs" "fnm not installed"
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
