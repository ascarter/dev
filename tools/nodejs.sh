#!/bin/sh

# Node.js toolchain management via fnm

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_BIN_HOME=${XDG_BIN_HOME:-${XDG_DATA_HOME}/../bin}
FNM_DIR="${FNM_DIR:-${XDG_DATA_HOME}/fnm}"

# Source log library for performance
. "$(dirname "$0")/../lib/log.sh"

install() {
  # Check if fnm is already installed
  if [ -d "${FNM_DIR}" ] && [ -x "${FNM_DIR}/fnm" ]; then
    log info "nodejs" "fnm already installed, skipping"
    status
    return 0
  fi

  log info "nodejs" "installing fnm to ${FNM_DIR}"
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell --install-dir "${FNM_DIR}" --force-install
}

update() {
  if ! [ -d "${FNM_DIR}" ] || ! [ -x "${FNM_DIR}/fnm" ]; then
    log info "nodejs" "fnm not installed"
    return 1
  fi

  log info "nodejs" "updating fnm"
  # fnm doesn't have built-in self-update, so reinstall
  install
}

uninstall() {
  if [ -d "${FNM_DIR}" ] || command -v fnm >/dev/null 2>&1; then
    log info "nodejs" "removing fnm installation"

    # Remove FNM directory
    if [ -d "${FNM_DIR}" ]; then
      rm -rf "${FNM_DIR}"
    fi
  else
    log info "nodejs" "fnm already uninstalled"
  fi
}

status() {
  if [ -d "${FNM_DIR}" ] && [ -x "${FNM_DIR}/fnm" ]; then
    local fnm_version node_version
    fnm_version=$("${FNM_DIR}/fnm" --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")

    # Check if Node.js is available via fnm
    if command -v node >/dev/null 2>&1; then
      node_version=$(node --version 2>/dev/null | sed 's/^v//' || echo "none")
      log info "nodejs" "fnm ${fnm_version}, node ${node_version}"
    else
      log info "nodejs" "fnm ${fnm_version}, node not installed"
    fi
  else
    log info "nodejs" "not installed"
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
