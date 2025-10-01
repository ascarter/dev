#!/bin/sh

# cosign management via ubi
#
# cosign is a container signing and verification tool

XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}

# Source devlog library for performance
. "$(dirname "$0")/../bin/devlog"

_do_install() {
  # Internal function that actually performs the installation
  log info "cosign" "installing cosign to ${XDG_BIN_HOME}"

  if ! command -v ubi >/dev/null 2>&1; then
    log error "cosign" "ubi is not installed, please install it first"
    return 1
  fi

  # Create the directory if it doesn't exist
  mkdir -p "${XDG_BIN_HOME}"

  if ! ubi --project sigstore/cosign --in "${XDG_BIN_HOME}"; then
    log error "cosign" "installation failed"
    return 1
  fi

  log info "cosign" "installation complete"
}

install() {
  # Check if cosign is already installed
  if command -v cosign >/dev/null 2>&1; then
    log info "cosign" "already installed, skipping"
    status
    return 0
  fi

  _do_install
}

update() {
  if ! command -v cosign >/dev/null 2>&1; then
    log info "cosign" "not installed"
    return 1
  fi

  log info "cosign" "updating cosign"

  # Call internal install function to reinstall
  _do_install
}

uninstall() {
  if ! [ -f "${XDG_BIN_HOME}/cosign" ]; then
    log info "cosign" "already uninstalled"
    return 0
  fi

  # Remove the binary
  rm -f "${XDG_BIN_HOME}/cosign"
  log info "cosign" "removed binary: ${XDG_BIN_HOME}/cosign"

  log info "cosign" "uninstall complete"
}

status() {
  if command -v cosign >/dev/null 2>&1; then
    local version
    version=$(cosign version 2>&1 | head -1 || echo "unknown")
    log info "cosign" "${version}"
  else
    log info "cosign" "not installed"
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
