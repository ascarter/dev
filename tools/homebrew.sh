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

log() {
  if [ "$#" -eq 1 ]; then
    printf "%s\n" "$1"
  elif [ "$#" -gt 1 ]; then
    printf "$(tput bold)%-10s$(tput sgr0)\t%s\n" "$1" "$2"
  fi
}

install() {
  if [ -d "${HOMEBREW_PREFIX}" ] && command -v brew >/dev/null 2>&1; then
    log "homebrew" "already installed"
    status
    return 0
  fi

  log "homebrew" "installing to ${HOMEBREW_PREFIX}"
  env ${HOMEBREW_INTERACTIVE} /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if command -v brew >/dev/null 2>&1; then
    eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"
  fi

  # Post-install configuration
  case "$(uname -s)" in
  Darwin)
    # Enable man page contextual menu item in Terminal.app
    if ! [ -f /usr/local/etc/man.d/homebrew.man.conf ]; then
      log "homebrew" "configuring man pages"
      sudo mkdir -p /usr/local/etc/man.d
      echo "MANPATH /opt/homebrew/share/man" | sudo tee -a /usr/local/etc/man.d/homebrew.man.conf >/dev/null
    fi
    ;;
  esac

  log "homebrew" "installation complete"
}

update() {
  if ! command -v brew >/dev/null 2>&1; then
    log "homebrew" "not installed"
    return 1
  fi

  log "homebrew" "updating homebrew"
  brew update
  brew upgrade
  brew cleanup
}

uninstall() {
  if [ -d "${HOMEBREW_PREFIX}" ]; then
    log "homebrew" "uninstalling from ${HOMEBREW_PREFIX}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
  else
    log "homebrew" "not installed"
  fi
}

status() {
  if command -v brew >/dev/null 2>&1; then
    local version
    version=$(brew --version 2>/dev/null | head -1 || echo "unknown")
    log "homebrew" "installed: ${version}"
  else
    log "homebrew" "not installed"
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
