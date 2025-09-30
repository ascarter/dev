#!/bin/sh

# Setup Steam

set -eu

# Use devlog for consistent logging
log() {
  "$(dirname "$0")/../bin/devlog" "$@"
}

case $(uname -s) in
Darwin)
  # Use homebrew to install Steam
  if command -v brew >/dev/null 2>&1; then
    brew install --adopt --cask steam
    softwareupdate --install-rosetta --agree-to-license
  else
    log error "Homebrew is not installed. Please install Homebrew first."
    exit 1
  fi
  ;;
Linux)
  if [ -f /etc/os-release ]; then
    . /etc/os-release
  fi

  case "$ID" in
  fedora)
    case "${VARIANT_ID}" in
    silverblue | cosmic-atomic)
      rpm-ostree install --idempotent -y steam-devices
      ;;
    *)
      sudo dnf install steam-devices
      ;;
    esac
    ;;
  debian | ubuntu)
    sudo apt-get upgrade && sudo apt-get update -y
    sudo apt-get install -y steam-devices
    ;;
  esac

  # Install Steam flatpak
  if ! command -v flatpak >/dev/null 2>&1; then
    log error "Flatpak is not installed. Please install Flatpak before running this script."
    exit 1
  fi

  flatpak update -y
  flatpak install -y flathub com.valvesoftware.Steam
  ;;
esac
