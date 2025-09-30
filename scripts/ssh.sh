#!/bin/sh

# SSH configuration script

set -eu

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
      echo "Creating symlink for sk-libfido2.dylib"
      sudo ln -s "${HOMEBREW_PREFIX}/lib/sk-libfido2.dylib" /usr/local/lib/sk-libfido2.dylib
    else
      echo "Symlink for sk-libfido2.dylib already exists"
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
    echo "$INCLUDE_LINE" >"$TEMP_CONFIG"
    echo "" >>"$TEMP_CONFIG"
    cat "$SSH_CONFIG" >>"$TEMP_CONFIG"
    mv "$TEMP_CONFIG" "$SSH_CONFIG"
    echo "Added: Include dotfiles ssh config"
  fi
else
  echo "Warning: Dotfiles SSH config not found at $DOTFILES_SSH_CONFIG"
fi

# Add security key providers
SECURITY_KEY_LINE=""

# Check for libfido2 library in common locations
fido2_libs="/usr/local/lib/sk-libfido2.dylib /usr/lib/x86_64-linux-gnu/sk-libfido2.so /usr/lib/sk-libfido2.so /usr/local/lib/sk-libfido2.so"
for lib_path in $fido2_libs; do
  if [ -e "$lib_path" ]; then
    echo "Setting SecurityKeyProvider $lib_path"
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
  echo "Setting SSH_ASKPASS launchctl environment variable..."
  launchctl setenv SSH_ASKPASS "${DOTFILES}/bin/ssh-askpass"
  launchctl setenv SSH_ASKPASS_REQUIRE force
  ;;
esac

# Set permissions on SSH config
chmod 700 "${SSH_DIR}"
chmod 600 "${SSH_CONFIG}"

echo "SSH configuration complete!"
echo ""
echo "SSH config location: $SSH_CONFIG"
echo "dotfiles SSH config: $DOTFILES_SSH_CONFIG"

# Display helpful information
case $(uname -s) in
Darwin)
  if [ -n "$HOMEBREW_PREFIX" ] && [ -f "${HOMEBREW_PREFIX}/lib/sk-libfido2.dylib" ]; then
    echo ""
    echo "Security key support is now configured!"
    echo "To generate a resident key:"
    echo "  ssh-keygen -t ed25519-sk -O resident -O verify-required -f ~/.ssh/id_ed25519_sk"
    echo "To load resident keys from your security key:"
    echo "  ssh-add -K"
  fi
  ;;
esac
