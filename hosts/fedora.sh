#!/bin/sh

# Fedora host provisioning script

set -eu

# Source devlog library for performance
. "$(dirname "$0")/../bin/devlog.sh"

# Verify Linux
if [ "$(uname -s)" != "Linux" ]; then
  log error "Fedora Linux only"
  exit 1
fi

if [ -f /etc/os-release ]; then
  . /etc/os-release
fi

if [ "$ID" != "fedora" ]; then
  log error "Fedora Linux only"
  exit 1
fi

log info "fedora" "Provisioning Fedora host ($VARIANT_ID)"

# Update firmware
if command -v fwupdmgr >/dev/null 2>&1; then
  log info "firmware" "Updating firmware..."
  sudo fwupdmgr refresh --force
  sudo fwupdmgr update
fi

case "$VARIANT_ID" in
silverblue | cosmic-atomic)
  log info "atomic" "Fedora Atomic variant detected"

  # Update rpm-ostree
  log info "rpm-ostree" "Updating rpm-ostree..."
  rpm-ostree upgrade

  # Install rpm overlays
  case "${XDG_CURRENT_DESKTOP:-}" in
  COSMIC)
    log info "desktop" "COSMIC desktop detected"
    # Add cosmic specific overlays here if needed
    ;;
  GNOME)
    log info "desktop" "GNOME desktop detected"
    log info "gnome" "Installing GNOME tweaks..."
    rpm-ostree install --idempotent gnome-tweaks
    log info "gnome" "Configuring GNOME settings..."
    gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,close
    ;;
  esac

  # Update flatpaks
  if command -v flatpak >/dev/null 2>&1; then
    log info "flatpak" "Updating Flatpaks..."
    if command -v dev >/dev/null 2>&1; then
      dev tool flatpak update
    else
      flatpak update -y
    fi
  fi
  ;;

server)
  log info "fedora" "Fedora Server detected"
  log info "dnf" "Installing base packages..."
  sudo dnf install -y dnf-plugins-core curl git
  log info "dnf" "Updating packages..."
  sudo dnf upgrade -y
  ;;

workstation | wsl)
  log info "fedora" "Fedora Workstation/WSL detected"
  log info "dnf" "Installing base packages..."
  sudo dnf install -y dnf-plugins-core @development-tools curl git zsh
  log info "dnf" "Updating packages..."
  sudo dnf upgrade -y
  ;;

*)
  log warn "fedora" "Fedora $VARIANT_ID not fully supported"
  log info "dnf" "Installing base packages..."
  sudo dnf install -y curl git
  log info "dnf" "Updating packages..."
  sudo dnf upgrade -y
  ;;
esac

log ""
log info "fedora" "Provisioning complete"
log info "fedora" "Run 'systemctl reboot' to restart if needed"
