#!/bin/sh

# Helix editor management via ubi
#
# Helix is a post-modern modal text editor

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
HELIX_HOME="${XDG_DATA_HOME}/helix"
XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}
ZSH_COMPLETIONS="${XDG_DATA_HOME}/zsh/completions"

# Source devlog library for performance
. "$(dirname "$0")/../bin/devlog"

_do_install() {
  # Internal function that actually performs the installation
  log info "helix" "installing Helix editor to ${HELIX_HOME}"

  if ! command -v ubi >/dev/null 2>&1; then
    log error "helix" "ubi is not installed, please install it first"
    return 1
  fi

  # Create the directories if they don't exist
  mkdir -p "${HELIX_HOME}"
  mkdir -p "${XDG_BIN_HOME}"
  mkdir -p "${ZSH_COMPLETIONS}"

  if ! ubi --project helix-editor/helix --in "${HELIX_HOME}" --extract-all; then
    log error "helix" "installation failed"
    return 1
  fi

  # Create symlink in XDG_BIN_HOME
  if [ -e "${XDG_BIN_HOME}/hx" ]; then
    rm -f "${XDG_BIN_HOME}/hx"
  fi
  ln -s "${HELIX_HOME}/hx" "${XDG_BIN_HOME}/hx"
  log info "helix" "symlinked ${XDG_BIN_HOME}/hx -> ${HELIX_HOME}/hx"

  # Create completion symlink in central completions directory
  if [ -f "${HELIX_HOME}/contrib/completion/hx.zsh" ]; then
    ln -sf "${HELIX_HOME}/contrib/completion/hx.zsh" "${ZSH_COMPLETIONS}/_hx"
    log info "helix" "installed completion to ${ZSH_COMPLETIONS}/_hx"
  fi

  log info "helix" "installation complete"
}

install() {
  # Check if helix is already installed
  if command -v hx >/dev/null 2>&1; then
    log info "helix" "already installed, skipping"
    status
    return 0
  fi

  _do_install
}

update() {
  if ! command -v hx >/dev/null 2>&1; then
    log info "helix" "not installed"
    return 1
  fi

  log info "helix" "updating Helix editor"

  # Call internal install function to reinstall
  _do_install
}

uninstall() {
  if ! [ -d "${HELIX_HOME}" ]; then
    log info "helix" "already uninstalled"
    return 0
  fi

  # Remove the symlink in XDG_BIN_HOME
  if [ -L "${XDG_BIN_HOME}/hx" ]; then
    rm -f "${XDG_BIN_HOME}/hx"
    log info "helix" "removed symlink: ${XDG_BIN_HOME}/hx"
  fi

  # Remove completion symlink
  if [ -L "${ZSH_COMPLETIONS}/_hx" ]; then
    rm -f "${ZSH_COMPLETIONS}/_hx"
    log info "helix" "removed completion: ${ZSH_COMPLETIONS}/_hx"
  fi

  # Remove the installation directory if it exists and is in our data home
  if [ -d "${HELIX_HOME}" ]; then
    rm -rf "${HELIX_HOME}"
    log info "helix" "removed directory: ${HELIX_HOME}"
  fi

  log info "helix" "uninstall complete"
}

status() {
  if command -v hx >/dev/null 2>&1; then
    local version
    version=$(hx --version 2>&1 | head -1 || echo "unknown")
    log info "helix" "${version}"
  else
    log info "helix" "not installed"
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
