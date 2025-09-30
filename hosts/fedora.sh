#!/bin/sh

# Fedora host provisioning script

set -eu

# Verify Linux
if [ "$(uname -s)" != "Linux" ]; then
  echo "Fedora Linux only" >&2
  exit 1
fi

if [ -f /etc/os-release ]; then
  . /etc/os-release
fi

if [ "$ID" != "fedora" ]; then
  echo "Fedora Linux only" >&2
  exit 1
fi

ACTION="${1:-provision}"

case "$ACTION" in
provision)
  echo "==> Provisioning Fedora host ($VARIANT_ID)"

  # Update firmware
  if command -v fwupdmgr >/dev/null 2>&1; then
    echo "Updating firmware..."
    sudo fwupdmgr refresh --force
    sudo fwupdmgr update
  fi

  case "$VARIANT_ID" in
  silverblue | cosmic-atomic)
    echo "Fedora Atomic variant detected"
    
    # Update rpm-ostree
    echo "Updating rpm-ostree..."
    rpm-ostree upgrade

    # Install rpm overlays
    case "${XDG_CURRENT_DESKTOP:-}" in
    COSMIC)
      echo "COSMIC desktop detected"
      # Add cosmic specific overlays here if needed
      ;;
    GNOME)
      echo "GNOME desktop detected"
      rpm-ostree install --idempotent gnome-tweaks
      gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,close
      ;;
    esac

    # Update flatpaks
    if command -v flatpak >/dev/null 2>&1; then
      echo "Updating Flatpaks..."
      flatpak update -y
    fi
    ;;
  
  server)
    echo "Fedora Server detected"
    sudo dnf install -y dnf-plugins-core curl git
    ;;
  
  workstation | wsl)
    echo "Fedora Workstation/WSL detected"
    sudo dnf install -y dnf-plugins-core @development-tools curl git zsh
    ;;
  
  *)
    echo "Fedora $VARIANT_ID not fully supported" >&2
    echo "Installing base packages..."
    sudo dnf install -y curl git
    ;;
  esac

  echo "Fedora host provisioning complete"
  echo "Run 'systemctl reboot' to restart if needed"
  ;;

update)
  echo "==> Updating Fedora host"

  case "$VARIANT_ID" in
  silverblue | cosmic-atomic)
    echo "Updating rpm-ostree..."
    rpm-ostree upgrade
    
    if command -v flatpak >/dev/null 2>&1; then
      echo "Updating Flatpaks..."
      flatpak update -y
    fi
    ;;
  *)
    echo "Updating packages..."
    sudo dnf upgrade -y
    ;;
  esac

  echo "Fedora host update complete"
  ;;

*)
  echo "Usage: $0 [provision|update]" >&2
  exit 1
  ;;
esac
