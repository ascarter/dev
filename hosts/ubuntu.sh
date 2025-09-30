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

echo "==> Provisioning $ID host"

echo "Updating package lists..."
sudo apt-get update

echo "Installing base packages..."
sudo apt-get install -y curl git gpg zsh build-essential

echo "Upgrading packages..."
sudo apt-get upgrade -y

echo "Removing unused packages..."
sudo apt-get autoremove -y

echo ""
echo "$ID host provisioning complete"
