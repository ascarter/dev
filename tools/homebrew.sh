#!/bin/sh

# Homebrew package manager

set -eu

case "$(uname -s)" in
Darwin)
  HOMEBREW_PREFIX="/opt/homebrew"
  HOMEBREW_INTERACTIVE=""
  ;;
Linux)
  HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
  HOMEBREW_INTERACTIVE="NONINTERACTIVE=1"
  ;;
esac

# Source devlog library for performance
. "$(dirname "$0")/../bin/devlog.sh"

install() {
  if [ -d "${HOMEBREW_PREFIX}" ] && [ -x "${HOMEBREW_PREFIX}/bin/brew" ]; then
    log info "homebrew" "already installed"
    return 0
  fi

  log info "homebrew" "installing to ${HOMEBREW_PREFIX}"
  env ${HOMEBREW_INTERACTIVE} /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if command -v brew >/dev/null 2>&1; then
    eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"
  fi

  # Post-install configuration
  case "$(uname -s)" in
  Darwin)
    # Enable man page contextual menu item in Terminal.app
    if ! [ -f /usr/local/etc/man.d/homebrew.man.conf ]; then
      log info "homebrew" "configuring man pages"
      sudo mkdir -p /usr/local/etc/man.d
      echo "MANPATH /opt/homebrew/share/man" | sudo tee -a /usr/local/etc/man.d/homebrew.man.conf >/dev/null
    fi
    ;;
  esac

  log info "homebrew" "installation complete"
}

update() {
  if ! command -v brew >/dev/null 2>&1; then
    log info "homebrew" "not installed"
    return 1
  fi

  log info "homebrew" "updating Homebrew"
  brew update
  brew upgrade
  brew cleanup
}

uninstall() {
  if [ -d "${HOMEBREW_PREFIX}" ]; then
    log info "homebrew" "uninstalling from ${HOMEBREW_PREFIX}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
  else
    log info "homebrew" "not installed"
  fi
}

status() {
  if command -v brew >/dev/null 2>&1; then
    local version
    version=$(brew --version 2>/dev/null | head -1 || echo "unknown")
    log info "homebrew" "installed: ${version}"
  else
    log info "homebrew" "not installed"
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
