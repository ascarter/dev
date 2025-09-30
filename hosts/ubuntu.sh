#!/bin/sh

# Ubuntu/Debian host provisioning script

set -eu

# Verify Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "Ubuntu/Debian only" >&2
  exit 1
fi

# Verify Ubuntu/Debian
if [ -f /etc/os-release ]; then
  . /etc/os-release
fi

case "${ID}" in
debian | ubuntu) ;;
*)
  echo "Ubuntu/Debian only" >&2
  exit 1
  ;;
esac

ACTION="${1:-provision}"

case "$ACTION" in
provision)
  echo "==> Provisioning $ID host"

  echo "Updating package lists..."
  sudo apt-get update

  echo "Installing base packages..."
  sudo apt-get install -y curl git gpg zsh build-essential

  echo "$ID host provisioning complete"
  ;;

update)
  echo "==> Updating $ID host"

  echo "Updating package lists..."
  sudo apt-get update

  echo "Upgrading packages..."
  sudo apt-get upgrade -y

  echo "Removing unused packages..."
  sudo apt-get autoremove -y

  echo "$ID host update complete"
  ;;

*)
  echo "Usage: $0 [provision|update]" >&2
  exit 1
  ;;
esac
