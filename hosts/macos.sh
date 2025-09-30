#!/bin/sh

# macOS host provisioning script

set -eu

# Verify macOS
if [ "$(uname -s)" != "Darwin" ]; then
  echo "macOS only" >&2
  exit 1
fi

echo "==> Provisioning macOS host"

# Xcode command line tools
if ! [ -e /Library/Developer/CommandLineTools ]; then
  echo "Installing Xcode command line tools..."
  xcode-select --install
  read -p "Press [Enter] when installation completes..." -n1 -s
  echo
  sudo xcodebuild -runFirstLaunch
else
  echo "Xcode command line tools: OK"
fi

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  # Use dev tool to install homebrew if dev command is available
  if command -v dev >/dev/null 2>&1; then
    dev tool homebrew install
  else
    # Fallback to direct installation
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Ensure brew is in PATH
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  echo "Homebrew: OK"
fi

# Update and install Brewfile packages
if command -v brew >/dev/null 2>&1; then
  echo "Updating Homebrew..."
  brew update

  echo "Checking Brewfile..."
  if ! brew bundle check --global; then
    echo "Installing/updating Brewfile packages..."
    brew bundle install --global
  else
    echo "Brewfile: OK"
  fi

  echo "Upgrading packages..."
  brew upgrade

  echo "Cleaning up..."
  brew cleanup
fi

# Enable developer mode
echo "Enabling developer mode..."
spctl developer-mode enable-terminal 2>/dev/null || true

# Terminal preferences
echo "Setting Terminal preferences..."
defaults write com.apple.terminal FocusFollowsMouse -string true

echo ""
echo "macOS host provisioning complete"
