#!/bin/sh

# macOS host provisioning script

set -eu

# Verify macOS
if [ "$(uname -s)" != "Darwin" ]; then
  echo "macOS only" >&2
  exit 1
fi

ACTION="${1:-provision}"

case "$ACTION" in
provision)
  echo "==> Provisioning macOS host"

  # Xcode command line tools
  if ! [ -e /Library/Developer/CommandLineTools ]; then
    echo "Installing Xcode command line tools..."
    xcode-select --install
    read -p "Press [Enter] when installation completes..." -n1 -s
    echo
    sudo xcodebuild -runFirstLaunch
  else
    echo "Xcode command line tools already installed"
  fi

  # Homebrew
  HOMEBREW_PREFIX="/opt/homebrew"
  if ! [ -d "${HOMEBREW_PREFIX}" ]; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"
  else
    echo "Homebrew already installed"
  fi

  # Install Brewfile packages
  if command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew packages..."
    brew bundle check --global || brew bundle install --global
  fi

  # Enable developer mode
  echo "Enabling developer mode..."
  spctl developer-mode enable-terminal 2>/dev/null || true

  # Terminal preferences
  echo "Setting Terminal preferences..."
  defaults write com.apple.terminal FocusFollowsMouse -string true

  echo "macOS host provisioning complete"
  ;;

update)
  echo "==> Updating macOS host"
  
  if command -v brew >/dev/null 2>&1; then
    echo "Updating Homebrew..."
    brew update
    brew upgrade
    brew cleanup
  fi

  echo "macOS host update complete"
  ;;

*)
  echo "Usage: $0 [provision|update]" >&2
  exit 1
  ;;
esac
