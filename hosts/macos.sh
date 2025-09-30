#!/bin/sh

# macOS host provisioning script

set -eu

# Source devlog library for performance
. "$(dirname "$0")/../bin/devlog.sh"

# Verify macOS
if [ "$(uname -s)" != "Darwin" ]; then
  log error "macOS only"
  exit 1
fi

log info "macos" "Provisioning macOS host"

# Xcode command line tools
if ! [ -e /Library/Developer/CommandLineTools ]; then
  log info "xcode" "Installing command line tools..."
  xcode-select --install
  read -p "Press [Enter] when installation completes..." -n1 -s
  echo
  sudo xcodebuild -runFirstLaunch
else
  log info "xcode" "Command line tools: OK"
fi

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  log info "homebrew" "Installing Homebrew..."
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
  log info "homebrew" "Homebrew: OK"
fi

# Update and install Brewfile packages
if command -v brew >/dev/null 2>&1; then
  log info "homebrew" "Updating Homebrew..."
  brew update

  log info "brewfile" "Checking Brewfile..."
  if ! brew bundle check --global; then
    log info "brewfile" "Installing/updating packages..."
    brew bundle install --global
  else
    log info "brewfile" "Brewfile: OK"
  fi

  log info "homebrew" "Upgrading packages..."
  brew upgrade

  log info "homebrew" "Cleaning up..."
  brew cleanup
fi

# Enable developer mode
log info "security" "Enabling developer mode..."
spctl developer-mode enable-terminal 2>/dev/null || true

# Terminal preferences
log info "terminal" "Setting Terminal preferences..."
defaults write com.apple.terminal FocusFollowsMouse -string true

log ""
log info "macos" "Provisioning complete"
