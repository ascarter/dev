#!/bin/sh

# Generate machine-specific git configuration at ~/.gitconfig
#
# This script configures:
# - User identity (from gh CLI + system fullname)
# - Credentials (gh CLI for GitHub, GCM for Azure DevOps if available)
# - Commit signing (GPG with YubiKey if available)
# - GUI tools (opendiff on macOS)
# - Git LFS (if installed)
#
# Machine-independent settings (aliases, colors, etc.) are in $XDG_CONFIG_HOME/git/config

set -eu

GIT_CONFIG_FILE="${HOME}/.gitconfig"

# Use devlog for consistent logging
log() {
  "$(dirname "$0")/../bin/devlog" log "$@"
}

# Configure user identity
configure_user() {
  # Clear existing user config
  git config --global --unset user.name 2>/dev/null || true
  git config --global --unset user.email 2>/dev/null || true

  # Get full name from system
  fullname=""
  if command -v id >/dev/null 2>&1; then
    fullname=$(id -F 2>/dev/null || true)
  fi

  # Fallback to other methods if id -F doesn't work
  if [ -z "$fullname" ]; then
    fullname=$(getent passwd "$USER" 2>/dev/null | cut -d: -f5 | cut -d, -f1 || true)
  fi

  # Final fallback
  if [ -z "$fullname" ]; then
    fullname="$USER"
  fi

  # Require GitHub CLI to be logged in
  if ! command -v gh >/dev/null 2>&1; then
    log "error" "GitHub CLI (gh) is not installed"
    exit 1
  fi

  ghuser=$(gh api user --jq '.login' 2>/dev/null || true)
  if [ -z "$ghuser" ]; then
    log "error" "Not logged into GitHub CLI. Run 'gh auth login' first."
    exit 1
  fi

  email="${ghuser}@users.noreply.github.com"

  git config --global user.name "$fullname"
  git config --global user.email "$email"

  log "user" "$fullname <$email>"
}

# Configure git credential managers
configure_credentials() {
  # Clear default credential helper
  git config --global --unset-all credential.helper 2>/dev/null || true

  # Use GitHub CLI for GitHub authentication
  if command -v gh >/dev/null 2>&1; then
    log "credentials" "gh (GitHub)"
    gh auth setup-git
  fi

  # Configure Azure DevOps if GCM is installed
  if command -v git-credential-manager >/dev/null 2>&1; then
    log "credentials" "GCM (Azure DevOps)"

    az_urls="https://dev.azure.com https://*.visualstudio.com"
    for url in $az_urls; do
      git config --global --unset-all credential.${url}.helper 2>/dev/null || true
      git config --global --unset credential.${url}.useHttpPath 2>/dev/null || true
      git config --global --unset credential.${url}.azreposCredentialType 2>/dev/null || true

      git config --global --add credential.${url}.helper ''
      git config --global --add credential.${url}.helper "$(command -v git-credential-manager)"
      git config --global credential.${url}.useHttpPath true
      git config --global credential.${url}.azreposCredentialType oauth
    done
  fi
}

# Configure commit signing with GPG
configure_signing() {
  # Clear signing keys
  git config --global --unset-all user.signingkey 2>/dev/null || true
  git config --global --unset gpg.format 2>/dev/null || true
  git config --global --unset gpg.ssh.program 2>/dev/null || true
  git config --global --unset gpg.program 2>/dev/null || true
  git config --global --unset commit.gpgsign 2>/dev/null || true
  git config --global --unset tag.gpgsign 2>/dev/null || true
  git config --global --unset gpg.ssh.allowedSignersFile 2>/dev/null || true

  # Check if GPG is installed and configured
  if ! command -v gpg >/dev/null 2>&1; then
    log "signing" "GPG not installed - skipping"
    return
  fi

  # Get the full path to gpg
  gpg_path=$(command -v gpg)

  # Get the signing key ID from YubiKey
  # Parse colon-separated output: find first secret subkey (ssb) with signing capability (s)
  signing_key=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^ssb/ && $12 ~ /s/ {print $5; exit}' || true)

  if [ -n "$signing_key" ]; then
    log "signing" "YubiKey GPG key: $signing_key"
    git config --global user.signingkey "$signing_key"
    git config --global gpg.program "$gpg_path"
    git config --global commit.gpgsign true
    git config --global tag.gpgsign true
  else
    log "signing" "No YubiKey GPG key found - skipping"
  fi
}

# Configure GUI tools
configure_tools() {
  git config --global --unset-all diff.guitool 2>/dev/null || true
  git config --global --unset-all merge.guitool 2>/dev/null || true

  # Use opendiff on macOS for gui diff/merge tools
  if command -v opendiff >/dev/null 2>&1; then
    log "gui tools" "opendiff"
    git config --global diff.tool "opendiff"
    git config --global diff.guitool "opendiff"
    git config --global merge.tool "opendiff"
    git config --global merge.guitool "opendiff"
  fi
}

# Configure Git LFS
configure_lfs() {
  if command -v git-lfs >/dev/null 2>&1; then
    log "lfs" "installed"
    git lfs install
  fi
}

# Main
log "gitconfig" "Generating ${GIT_CONFIG_FILE}"
log ""

configure_user
configure_credentials
configure_signing
configure_tools
configure_lfs

log ""
log "gitconfig" "Configuration complete"
