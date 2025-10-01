#!/bin/sh

# Zed editor management
#
# Environment Variables:
#   ZED_CHANNEL - Channel to install (stable or preview, default: stable)
#
# Note: Zed auto-updates itself, so update command just ensures latest is installed

XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}
ZED_CHANNEL=${ZED_CHANNEL:-stable}

# Source devlog library for performance
. "$(dirname "$0")/../bin/devlog"

install() {
  # Check if zed is already installed
  if command -v zed >/dev/null 2>&1; then
    log info "zed" "already installed, skipping"
    status
    return 0
  fi

  log info "zed" "installing Zed editor (${ZED_CHANNEL} channel)"

  # Install via official script
  if ! curl -fsSL https://zed.dev/install.sh | ZED_CHANNEL=$ZED_CHANNEL sh; then
    log error "zed" "installation failed"
    return 1
  fi

  log info "zed" "installation complete"
}

update() {
  if ! command -v zed >/dev/null 2>&1; then
    log info "zed" "not installed"
    return 1
  fi

  log info "zed" "Zed auto-updates itself, reinstalling to ensure latest"

  # Zed auto-updates, but we can reinstall to ensure latest version
  if ! curl -fsSL https://zed.dev/install.sh | ZED_CHANNEL=$ZED_CHANNEL sh; then
    log error "zed" "update failed"
    return 1
  fi

  log info "zed" "update complete"
}

uninstall() {
  local removed=0

  # Remove CLI symlink
  if [ -L "${XDG_BIN_HOME}/zed" ]; then
    rm -f "${XDG_BIN_HOME}/zed"
    log info "zed" "removed CLI symlink: ${XDG_BIN_HOME}/zed"
    removed=1
  fi

  # Check for macOS app bundle
  if [ -d "/Applications/Zed.app" ]; then
    log warn "zed" "removing /Applications/Zed.app"
    rm -rf "/Applications/Zed.app"
    removed=1
  fi

  # Check for Zed Preview app bundle
  if [ -d "/Applications/Zed Preview.app" ]; then
    log warn "zed" "removing /Applications/Zed Preview.app"
    rm -rf "/Applications/Zed Preview.app"
    removed=1
  fi

  # Check for Linux installation
  if [ -d "${HOME}/.local/zed.app" ]; then
    log warn "zed" "removing ${HOME}/.local/zed.app"
    rm -rf "${HOME}/.local/zed.app"
    removed=1
  fi

  if [ $removed -eq 0 ]; then
    log info "zed" "already uninstalled"
  else
    log info "zed" "uninstall complete"
  fi
}

status() {
  if command -v zed >/dev/null 2>&1; then
    local version zed_path app_path channel
    version=$(zed --version 2>&1 | head -1 || echo "unknown")
    zed_path=$(command -v zed)

    # Detect channel from app path
    if [ -d "/Applications/Zed Preview.app" ]; then
      channel="preview"
      app_path="/Applications/Zed Preview.app"
    elif [ -d "/Applications/Zed.app" ]; then
      channel="stable"
      app_path="/Applications/Zed.app"
    elif [ -d "${HOME}/.local/zed.app" ]; then
      channel="stable"
      app_path="${HOME}/.local/zed.app"
    else
      channel="unknown"
      app_path="unknown"
    fi

    log info "zed" "installed at ${zed_path}, ${version}"
    log info "zed" "channel: ${channel}, app: ${app_path}"
  else
    log info "zed" "not installed"
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
