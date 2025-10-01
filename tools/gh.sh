#!/bin/sh

# GitHub CLI (gh) management via ubi
#
# GitHub CLI brings GitHub to your terminal

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
GH_HOME="${XDG_DATA_HOME}/gh"
XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}

# Source devlog library for performance
. "$(dirname "$0")/../bin/devlog"

_do_install() {
  # Internal function that actually performs the installation
  log info "gh" "installing GitHub CLI to ${GH_HOME}"

  if ! command -v ubi >/dev/null 2>&1; then
    log error "gh" "ubi is not installed, please install it first"
    return 1
  fi

  # Create the directory if it doesn't exist
  mkdir -p "${GH_HOME}"
  mkdir -p "${XDG_BIN_HOME}"

  if ! ubi --project cli/cli --in "${GH_HOME}" --extract-all; then
    log error "gh" "installation failed"
    return 1
  fi

  # Create symlink in XDG_BIN_HOME
  if [ -e "${XDG_BIN_HOME}/gh" ]; then
    rm -f "${XDG_BIN_HOME}/gh"
  fi
  ln -s "${GH_HOME}/bin/gh" "${XDG_BIN_HOME}/gh"
  log info "gh" "symlinked ${XDG_BIN_HOME}/gh -> ${GH_HOME}/bin/gh"

  log info "gh" "installation complete"
}

install() {
  # Check if gh is already installed
  if command -v gh >/dev/null 2>&1; then
    log info "gh" "already installed, skipping"
    status
    return 0
  fi

  _do_install
}

update() {
  if ! command -v gh >/dev/null 2>&1; then
    log info "gh" "not installed"
    return 1
  fi

  log info "gh" "updating GitHub CLI"

  # Call internal install function to reinstall
  _do_install
}

uninstall() {
  if ! [ -d "${GH_HOME}" ]; then
    log info "gh" "already uninstalled"
    return 0
  fi

  # Remove the symlink in XDG_BIN_HOME
  if [ -L "${XDG_BIN_HOME}/gh" ]; then
    rm -f "${XDG_BIN_HOME}/gh"
    log info "gh" "removed symlink: ${XDG_BIN_HOME}/gh"
  fi

  # Remove the installation directory if it exists and is in our data home
  if [ -d "${GH_HOME}" ]; then
    rm -rf "${GH_HOME}"
    log info "gh" "removed directory: ${GH_HOME}"
  fi

  log info "gh" "uninstall complete"
}

status() {
  if command -v gh >/dev/null 2>&1; then
    version=$(gh --version 2>&1 | head -1 || echo "unknown")
    gh_path=$(command -v gh)
    log info "gh" "installed at ${gh_path}, ${version}"
  else
    log info "gh" "not installed"
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
