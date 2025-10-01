#!/bin/sh

# OpenAI Codex CLI management via ubi
#
# Codex is a lightweight coding agent from OpenAI

XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}

# Source devlog library for performance
. "$(dirname "$0")/../bin/devlog"

_do_install() {
  # Internal function that actually performs the installation
  log info "codex" "installing codex to ${XDG_BIN_HOME}"

  if ! command -v ubi >/dev/null 2>&1; then
    log error "codex" "ubi is not installed, please install it first"
    return 1
  fi

  # Create the directory if it doesn't exist
  mkdir -p "${XDG_BIN_HOME}"

  if ! ubi --project openai/codex --in "${XDG_BIN_HOME}"; then
    log error "codex" "installation failed"
    return 1
  fi

  log info "codex" "installation complete"
}

install() {
  # Check if codex is already installed
  if command -v codex >/dev/null 2>&1; then
    log info "codex" "already installed, skipping"
    status
    return 0
  fi

  _do_install
}

update() {
  if ! command -v codex >/dev/null 2>&1; then
    log info "codex" "not installed"
    return 1
  fi

  log info "codex" "updating codex"

  # Call internal install function to reinstall
  _do_install
}

uninstall() {
  if ! [ -f "${XDG_BIN_HOME}/codex" ]; then
    log info "codex" "already uninstalled"
    return 0
  fi

  # Remove the binary
  rm -f "${XDG_BIN_HOME}/codex"
  log info "codex" "removed binary: ${XDG_BIN_HOME}/codex"

  log info "codex" "uninstall complete"
}

status() {
  if command -v codex >/dev/null 2>&1; then
    local version
    version=$(codex --version 2>&1 | head -1 || echo "unknown")
    log info "codex" "${version}"
  else
    log info "codex" "not installed"
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
