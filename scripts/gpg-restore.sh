#!/bin/sh
# gpg-restore.sh - Restore GPG key from backup to YubiKey
#
# Usage: ./gpg-restore.sh [backup_directory]
#        Default backup directory is current directory

set -eu

# Function to prompt for yes/no confirmation
prompt() {
  printf "%s (y/N): " "$1"
  read -r choice
  case "$choice" in
  [yY] | [yY][eE][sS]) return 0 ;;
  *) return 1 ;;
  esac
}

# Show usage
show_usage() {
  printf "Usage: $0 [backup_directory]\n"
  printf "\n"
  printf "Restores GPG key from backup to YubiKey.\n"
  printf "Default backup directory is current directory.\n"
  printf "\n"
  printf "Options:\n"
  printf "  -h    Show this help message\n"
}

# Parse options with getopts
while getopts "h" opt; do
  case $opt in
  h)
    show_usage
    exit 0
    ;;
  \?)
    printf "Invalid option: -$OPTARG\n" >&2
    show_usage
    exit 1
    ;;
  esac
done

# Shift past the options
shift $((OPTIND - 1))

# Set backup directory (default to current directory)
if [ $# -eq 0 ]; then
  BACKUP_DIR="."
elif [ $# -eq 1 ]; then
  BACKUP_DIR="$1"
else
  printf "Error: Too many arguments\n"
  printf "\n"
  show_usage
  exit 1
fi

printf "GPG YubiKey Restore Script\n"
printf "===============================\n"
printf "\n"

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
  printf "Error: Backup directory not found: $BACKUP_DIR\n"
  exit 1
fi

printf "Found backup directory: $BACKUP_DIR\n"

# Check if YubiKey is detected
if ! command -v ykman >/dev/null 2>&1; then
  printf "Error: ykman not found! Please install YubiKey Manager.\n"
  exit 1
fi

if ! ykman list | grep -q "YubiKey"; then
  printf "Error: No YubiKey detected!\n"
  printf "Please insert your YubiKey and try again.\n"
  exit 1
fi

printf "YubiKey detected\n"

# Show YubiKey info
printf "\nYubiKey Information:\n"
ykman info
printf "\n"

printf "Step 1: Inspecting backup...\n"
# Find master key file in backup directory
MASTER_FILE=$(find "$BACKUP_DIR" -name "*-master.asc" -type f | head -n1)

if [ -z "$MASTER_FILE" ]; then
  printf "Error: Could not locate master key file in backup\n"
  exit 1
fi

# Auto-detect the KEYID from the master key filename
KEYID=$(basename "$MASTER_FILE" | sed -E 's#-master\.asc$##')

if [ -z "$KEYID" ]; then
  printf "Error: Could not detect GPG key ID from backup files\n"
  exit 1
fi

printf "Detected Key ID: $KEYID\n"

# Locate optional README file in backup directory
README_FILE=$(find "$BACKUP_DIR" -name "README*" -type f | head -n1)

# Verify required files exist
printf "\nVerifying backup contents:\n"
for file in "${KEYID}-master.asc" "${KEYID}-subkeys.asc" "ownertrust.txt"; do
  if [ -f "$BACKUP_DIR/$file" ]; then
    printf "  %s\n" "$file"
  else
    printf "  %s (missing)\n" "$file"
    printf "Error: Required backup files are missing!\n"
    exit 1
  fi
done

# Check if key already exists locally
KEY_EXISTS=false
if gpg --list-secret-keys "$KEYID" >/dev/null 2>&1; then
  KEY_EXISTS=true
fi

# Check current YubiKey status
YUBIKEY_HAS_KEYS=false
if gpg --card-status 2>/dev/null | grep -E "(Signature key|Encryption key|Authentication key)" | grep -vq "\[none\]"; then
  YUBIKEY_HAS_KEYS=true
fi

# Display current state and options
printf "\nCurrent State Analysis:\n"
if [ "$KEY_EXISTS" = "true" ]; then
  printf "  GPG key $KEYID already exists locally\n"
else
  printf "  GPG key $KEYID not found locally\n"
fi

if [ "$YUBIKEY_HAS_KEYS" = "true" ]; then
  printf "  YubiKey already contains OpenPGP keys\n"
  gpg --card-status | grep -E "(Signature key|Encryption key|Authentication key)" | grep -v "\[none\]" | sed 's/^/    /'
else
  printf "  YubiKey OpenPGP applet is empty\n"
fi

# Determine operation mode
printf "\nOperation: Restore GPG key to YubiKey\n"
printf "This will import keys from backup and move subkeys to YubiKey.\n"

# Warning and confirmation
printf "\n"
if [ "$YUBIKEY_HAS_KEYS" = "true" ]; then
  printf "WARNING: This will reset the YubiKey's OpenPGP applet and erase existing keys!\n"
else
  printf "YubiKey appears empty. Reset is optional; you can skip to keep counters and settings, or reset to ensure a clean state.\n"
fi
if [ "$KEY_EXISTS" = "true" ]; then
  printf "   Local keys will be reimported from backup.\n"
fi

# Show backup README (if available) before proceeding
if [ -n "$README_FILE" ]; then
  printf "\nBackup README:\n"
  sed 's/^/    /' "$README_FILE"
fi

# Confirm operation
printf "\n"
if ! prompt "Continue with this operation?"; then
  printf "Operation cancelled.\n"
  exit 0
fi

# Reset YubiKey OpenPGP applet
if [ "$YUBIKEY_HAS_KEYS" = "true" ]; then
  printf "\nStep 2: Resetting YubiKey OpenPGP applet (existing keys detected)...\n"
  ykman openpgp reset
else
  printf "\nStep 2: YubiKey reset (optional)\n"
  if prompt "Reset the YubiKey OpenPGP applet before proceeding?"; then
    ykman openpgp reset
  else
    printf "Skipping YubiKey reset.\n"
  fi
fi

printf "\nStep 3: Cleaning up existing stubs for this key...\n"

# Remove only shadowed stubs corresponding to this key's keygrips (derived from backup, no import yet)
keygrips=$({
  cat "$BACKUP_DIR/${KEYID}-master.asc"
  cat "$BACKUP_DIR/${KEYID}-subkeys.asc"
} 2>/dev/null | gpg --show-keys --with-colons --with-keygrip 2>/dev/null | awk -F: '$1=="grp"{print $10}' | sort -u)
for grip in $keygrips; do
  f="$HOME/.gnupg/private-keys-v1.d/$grip.key"
  if [ -f "$f" ] && grep -q 'shadowed' "$f" 2>/dev/null; then
    rm -f "$f"
    printf "  Removed stub: %s\n" "$f"
  fi
done

printf "\nStep 4: Importing GPG keys from backup...\n"

# Import master key
printf "Importing master key...\n"
gpg --import "$BACKUP_DIR/${KEYID}-master.asc"

# Import subkeys
printf "Importing subkeys...\n"
gpg --import "$BACKUP_DIR/${KEYID}-subkeys.asc"

# Import trust settings
printf "Importing trust settings...\n"
gpg --import-ownertrust "$BACKUP_DIR/ownertrust.txt"

# Get user info for YubiKey configuration
uid_line=$(gpg --list-keys --with-colons "$KEYID" | awk -F: '$1=="uid"{print $10; exit}')
name=$(printf "%s" "$uid_line" | sed -E 's/ *<[^>]*>//; s/ *\([^)]*\)//; s/^ *//; s/ *$//')
login=$(printf "%s" "$uid_line" | sed -nE 's/.*<([^>]+)>.*/\1/p' | sed -E 's/@.*$//')
url="https://github.com/${login}.gpg"

printf "\nStep 5: YubiKey Configuration\n"

# Configure PINs via ykman
printf "Setting YubiKey PINs...\n"

# Change User PIN
printf "\nChanging User PIN (default: 123456)\n"
ykman openpgp access change-pin

# Change Admin PIN
printf "\nChanging Admin PIN (default: 12345678)\n"
ykman openpgp access change-admin-pin

printf "\nPINs configured successfully\n"

# Configure metadata
printf "\nSetting YubiKey metadata...\n"
printf "Configure your YubiKey with these settings:\n"
printf "  - Name: ${name}\n"
printf "  - Login: ${login}\n"
printf "  - URL: ${url}\n"
printf "\n"
printf "Press Enter to start metadata configuration..."
read dummy

# Configure YubiKey - user must do this interactively
printf "\nStarting metadata configuration...\n"
printf "In the GPG card editor, run these commands:\n"
printf "  admin       (enable admin commands)\n"
printf "  name        (enter: %s)\n" "$name"
printf "  login       (enter: %s)\n" "$login"
printf "  url         (enter: %s)\n" "$url"
printf "  quit        (exit the card editor)\n"
gpg --card-edit

printf "\nStep 6: Moving Subkeys to YubiKey\n"
printf "\nIMPORTANT: This will move your private subkeys to the YubiKey.\n"
printf "   After this, the subkeys will only exist on the YubiKey hardware!\n"
printf "\n"
printf "In the GPG key editing prompt, run these commands:\n"
printf "  key 2 (select signing subkey)\n"
printf "  keytocard -> select 1 (Signature key)\n"
printf "  key 2 (deselect)\n"
printf "  key 3 (select encryption subkey)\n"
printf "  keytocard -> select 2 (Encryption key)\n"
printf "  key 3 (deselect)\n"
printf "  key 4 (select authentication subkey)\n"
printf "  keytocard -> select 3 (Authentication key)\n"
printf "  save\n"
printf "\n"
printf "Press Enter to start the key transfer process..."
read dummy

# Start GPG edit session for moving keys to card
printf "\nStarting key transfer to YubiKey...\n"
gpg --expert --edit-key "$KEYID"

printf "\nStep 7: Verifying YubiKey setup...\n"
printf "YubiKey card status:\n"
gpg --card-status

printf "\nSecret keys status:\n"
gpg --list-secret-keys --keyid-format=long "$KEYID"

printf "\nYubiKey restore process complete!\n"

# Cleanup (no temporary files created during restore)

printf "\nNext steps:\n"
printf "1. Test GPG signing: echo 'test' | gpg --clearsign\n"
printf "2. Test Git signing: git commit --allow-empty -m 'Test GPG signing'\n"
printf "\nYour YubiKey is now ready to use!\n"
printf "\nMulti-YubiKey Usage:\n"
printf "- Run this script again with other YubiKeys to set them up identically\n"
printf "- All YubiKeys with the same subkeys work interchangeably\n"
printf "- GPG will work with whichever YubiKey is currently inserted\n"
