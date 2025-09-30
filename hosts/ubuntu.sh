#!/bin/sh

# Ubuntu/Debian host provisioning script

set -eu

# Use devlog for consistent logging
log() {
  "$(dirname "$0")/../bin/devlog" "$@"
}

# Verify Linux
if [ "$(uname -s)" != "Linux" ]; then
  log error "Ubuntu/Debian only"
  exit 1
fi

# Verify Ubuntu/Debian
if [ -f /etc/os-release ]; then
  . /etc/os-release
fi

case "${ID}" in
debian | ubuntu) ;;
*)
  log error "Ubuntu/Debian only"
  exit 1
  ;;
esac

log info "$ID" "Provisioning $ID host"

log info "apt" "Updating package lists..."
sudo apt-get update

log info "apt" "Installing base packages..."
sudo apt-get install -y curl git gpg zsh build-essential

log info "apt" "Upgrading packages..."
sudo apt-get upgrade -y

log info "apt" "Removing unused packages..."
sudo apt-get autoremove -y

log ""
log info "$ID" "Provisioning complete"
