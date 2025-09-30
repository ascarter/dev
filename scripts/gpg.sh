#!/bin/sh

# gpg configuration script

set -eu

# Set default values for environment variables if not already set
: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${DOTFILES:=${XDG_DATA_HOME:-${HOME}/.local/share}/dotfiles}"

# Function to prompt for yes/no confirmation
prompt() {
  printf "%s (y/N): " "$1"
  read -r choice
  case "$choice" in
  [yY] | [yY][eE][sS]) return 0 ;;
  *) return 1 ;;
  esac
}

case $(uname -s) in
Darwin)
  if command -v pinentry-mac >/dev/null 2>&1; then
    # Configure pinentry-mac to use the macOS keychain
    defaults write org.gpgtools.pinentry-mac UseKeychain -bool YES
    defaults write org.gpgtools.pinentry-mac DisableKeychain -bool NO

    # Set pinentry-mac as the default pinentry program in ~/.gnupg/gpg-agent.conf
    gpg_agent_conf="$HOME/.gnupg/gpg-agent.conf"
    pinentry_path=$(which pinentry-mac)

    # Create .gnupg directory if it doesn't exist with correct permissions
    mkdir -p "$HOME/.gnupg"
    chmod 700 "$HOME/.gnupg"

    # Check if pinentry-program is already set
    if [ ! -f "$gpg_agent_conf" ] || ! grep -q "^pinentry-program" "$gpg_agent_conf"; then
      echo "pinentry-program $pinentry_path" >>"$gpg_agent_conf"
    fi
  fi
  ;;
esac

# Check for YubiKey and offer to provision
if command -v ykman >/dev/null 2>&1; then
  if ykman list | grep -q "YubiKey"; then
    printf "\nYubiKey detected!\n"

    # Check if YubiKey already has GPG keys
    YUBIKEY_HAS_KEYS=false
    if gpg --card-status 2>/dev/null | grep -E "(Signature key|Encryption key|Authentication key)" | grep -vq "\[none\]"; then
      YUBIKEY_HAS_KEYS=true
      printf "YubiKey already contains GPG keys:\n"
      gpg --card-status | grep -E "(Signature key|Encryption key|Authentication key)" | grep -v "\[none\]" | sed 's/^/  /'
    else
      printf "YubiKey OpenPGP applet is empty (no keys configured)\n"
    fi

    # Offer to provision based on YubiKey state
    if [ "$YUBIKEY_HAS_KEYS" = "true" ]; then
      # YubiKey has keys - offer to fetch public key
      if prompt "Would you like to set up GPG to use this YubiKey?"; then
        printf "Fetching public key from YubiKey...\n"

        # Track if we successfully imported a key
        KEY_IMPORTED=false

        # Try to fetch from card URL first
        if gpg --card-edit --command-fd 0 <<EOF 2>/dev/null; then
fetch
quit
EOF
          printf "Public key fetched from card URL\n"
          KEY_IMPORTED=true
        else
          # If fetch fails, try to get from GitHub based on card login
          CARD_LOGIN=$(gpg --card-status 2>/dev/null | grep "Login data" | sed 's/.*: *//')
          if [ -n "$CARD_LOGIN" ]; then
            printf "Attempting to fetch public key from GitHub user: %s\n" "$CARD_LOGIN"
            if curl -fsSL "https://github.com/${CARD_LOGIN}.gpg" | gpg --import; then
              printf "Public key imported from GitHub\n"
              KEY_IMPORTED=true
            fi
          fi
        fi

        # Show manual instructions if all automatic methods failed
        if [ "$KEY_IMPORTED" = "false" ]; then
          printf "Could not fetch public key automatically\n"
          printf "Please import your public key manually:\n"
          printf "  gpg --import /path/to/public-key.asc\n"
          printf "  or: curl https://github.com/USERNAME.gpg | gpg --import\n"
        fi

        # Show card status
        printf "\nYubiKey GPG status:\n"
        gpg --card-status
      fi
    else
      # YubiKey is empty - inform user how to provision
      printf "\nYubiKey has no GPG keys configured.\n"
      printf "To provision this YubiKey with GPG keys, run:\n"
      printf "  dotfiles script gpg-restore /path/to/backup\n"
    fi
  fi
fi

# Import GitHub published GPG keys
ghuser=""
if command -v gh >/dev/null 2>&1; then
  ghuser=$(gh api user --jq '.login')
  curl -fsSL https://github.com/$ghuser.gpg | gpg --import
fi
