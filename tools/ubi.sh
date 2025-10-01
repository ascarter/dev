#!/bin/sh

# ubi - Universal Binary Installer management
#
# ubi is a tool for installing pre-built binaries from GitHub releases

XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}

# Source devlog library for performance
. "$(dirname "$0")/../bin/devlog"

_do_install() {
  # Internal function that actually performs the installation
  log info "ubi" "installing ubi to ${XDG_BIN_HOME}"

  if ! curl --silent --location \
    https://raw.githubusercontent.com/houseabsolute/ubi/master/bootstrap/bootstrap-ubi.sh |
    TARGET=${XDG_BIN_HOME} sh; then
    log error "ubi" "installation failed"
    return 1
  fi

  log info "ubi" "installation complete"
}

install() {
  # Check if ubi is already installed
  if command -v ubi >/dev/null 2>&1; then
    log info "ubi" "already installed, skipping"
    status
    return 0
  fi

  _do_install
}

update() {
  if ! command -v ubi >/dev/null 2>&1; then
    log info "ubi" "not installed"
    return 1
  fi

  log info "ubi" "updating ubi"

  # Call internal install function to reinstall
  _do_install
}

uninstall() {
  if ! command -v ubi >/dev/null 2>&1; then
    log info "ubi" "already uninstalled"
    return 0
  fi

  local ubi_path
  ubi_path=$(command -v ubi)

  if [ -f "${ubi_path}" ]; then
    rm -f "${ubi_path}"
    log info "ubi" "removed binary: ${ubi_path}"
    log info "ubi" "uninstall complete"
  else
    log warn "ubi" "command found but binary not at expected location"
    return 1
  fi
}

status() {
  if command -v ubi >/dev/null 2>&1; then
    local version
    version=$(ubi --version 2>&1 | head -1 || echo "unknown")
    log info "ubi" "${version}"
  else
    log info "ubi" "not installed"
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
