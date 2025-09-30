#!/bin/sh

# SSH configuration script

set -eu

# Use devlog for consistent logging
log() {
  "$(dirname "$0")/../bin/devlog" "$@"
}

# Set default values for environment variables if not already set
: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${DOTFILES:=${XDG_DATA_HOME:-${HOME}/.local/share}/dotfiles}"

SSH_CONFIG="${HOME}/.ssh/config"
SSH_DIR="${HOME}/.ssh"
DOTFILES_SSH_CONFIG="${XDG_CONFIG_HOME}/ssh/config"

# Configure security key helper
case $(uname -s) in
Darwin)
  if [ -f "${HOMEBREW_PREFIX}/lib/sk-libfido2.dylib" ]; then
    # Create /usr/local/lib if it doesn't exist
    if [ ! -d "/usr/local/lib" ]; then
      sudo mkdir -p /usr/local/lib
      sudo chown "root:wheel" /usr/local/lib
      sudo chmod 755 /usr/local/lib
    fi

    # Check if symlink already exists
    if [ ! -L "/usr/local/lib/sk-libfido2.dylib" ]; then
      log info "ssh" "Creating symlink for sk-libfido2.dylib"
      sudo ln -s "${HOMEBREW_PREFIX}/lib/sk-libfido2.dylib" /usr/local/lib/sk-libfido2.dylib
    else
      log info "ssh" "Symlink for sk-libfido2.dylib already exists"
    fi
  fi
  ;;
esac

# Create SSH config if it doesn't exist
if [ ! -f "${SSH_CONFIG}" ]; then
  mkdir -p "${SSH_DIR}"
  touch "${SSH_CONFIG}"
fi

# Add Include directive for dotfiles SSH config
if [ -f "$DOTFILES_SSH_CONFIG" ]; then
  INCLUDE_LINE="Include ${DOTFILES_SSH_CONFIG}"

  # Check if Include is already at the top of the file
  if ! head -n 5 "$SSH_CONFIG" | grep -q "Include.*${DOTFILES_SSH_CONFIG}"; then
    # Create a temporary file with the Include at the top
    TEMP_CONFIG=$(mktemp)
    printf "%s\n" "$INCLUDE_LINE" >"$TEMP_CONFIG"
    echo "" >>"$TEMP_CONFIG"
    cat "$SSH_CONFIG" >>"$TEMP_CONFIG"
    mv "$TEMP_CONFIG" "$SSH_CONFIG"
    log info "ssh" "Added: Include dotfiles ssh config"
  fi
else
  log warn "ssh" "Dotfiles SSH config not found at $DOTFILES_SSH_CONFIG"
fi

# Add security key providers
SECURITY_KEY_LINE=""

# Check for libfido2 library in common locations
fido2_libs="/usr/local/lib/sk-libfido2.dylib /usr/lib/x86_64-linux-gnu/sk-libfido2.so /usr/lib/sk-libfido2.so /usr/local/lib/sk-libfido2.so"
for lib_path in $fido2_libs; do
  if [ -e "$lib_path" ]; then
    log info "ssh" "Setting SecurityKeyProvider $lib_path"
    SECURITY_KEY_LINE="SecurityKeyProvider $lib_path"
    case $(uname -s) in
    Darwin)
      launchctl setenv SSH_SK_PROVIDER "$lib_path"
      ;;
    esac
    break
  fi
done

if [ -n "$SECURITY_KEY_LINE" ]; then
  if ! { [ -f "$SSH_CONFIG" ] && grep -q "SecurityKeyProvider.*" "$SSH_CONFIG"; }; then
    printf "\n%s\n\n" "$SECURITY_KEY_LINE" >>"$SSH_CONFIG"
  fi
fi

# Add SSH_ASKPASS configuration
case $(uname -s) in
Darwin)
  # Configure SSH_ASKPASS helper
  log info "ssh" "Setting SSH_ASKPASS launchctl environment variable..."
  launchctl setenv SSH_ASKPASS "${DOTFILES}/bin/ssh-askpass"
  launchctl setenv SSH_ASKPASS_REQUIRE force
  ;;
esac

# Set permissions on SSH config
chmod 700 "${SSH_DIR}"
chmod 600 "${SSH_CONFIG}"

log info "ssh" "SSH configuration complete!"
log ""
log info "ssh" "SSH config location: $SSH_CONFIG"
log info "ssh" "dotfiles SSH config: $DOTFILES_SSH_CONFIG"

# Display helpful information
case $(uname -s) in
Darwin)
  if [ -n "$HOMEBREW_PREFIX" ] && [ -f "${HOMEBREW_PREFIX}/lib/sk-libfido2.dylib" ]; then
    log ""
    log info "ssh" "Security key support is now configured!"
    log info "ssh" "To generate a resident key:"
    log info "ssh" "  ssh-keygen -t ed25519-sk -O resident -O verify-required -f ~/.ssh/id_ed25519_sk"
    log info "ssh" "To load resident keys from your security key:"
    log info "ssh" "  ssh-add -K"
  fi
  ;;
esac
