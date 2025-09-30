#!/bin/sh

# Flatpak application installer

set -eu

log() {
  if [ "$#" -eq 1 ]; then
    printf "%s\n" "$1"
  elif [ "$#" -gt 1 ]; then
    printf "$(tput bold)%-10s$(tput sgr0)\t%s\n" "$1" "$2"
  fi
}

install() {
  if ! command -v flatpak >/dev/null 2>&1; then
    log "flatpak" "flatpak not available on this system"
    return 1
  fi

  log "flatpak" "enabling Flathub remote"
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  log "flatpak" "updating flatpak repositories"
  flatpak update -y

  log "flatpak" "installing core applications"
  flatpak install -y flathub com.github.tchx84.Flatseal
  flatpak install -y flathub com.vivaldi.Vivaldi
  flatpak install -y flathub io.github.shiftey.Desktop
  flatpak install -y flathub io.missioncenter.MissionCenter
  flatpak install -y flathub io.podman_desktop.PodmanDesktop
  flatpak install -y flathub org.videolan.VLC

  # Desktop-specific applications
  case "${XDG_CURRENT_DESKTOP:-}" in
  COSMIC)
    log "flatpak" "installing COSMIC desktop applications"
    flatpak install -y flathub com.jwestall.Forecast
    flatpak install -y flathub dev.deedles.Trayscale
    flatpak install -y flathub dev.edfloreshz.Calculator
    flatpak install -y flathub io.github.cosmic_utils.Examine
    ;;
  GNOME)
    log "flatpak" "installing GNOME desktop applications"
    flatpak install -y fedora org.gnome.Connections
    flatpak install -y fedora org.gnome.Extensions
    flatpak install -y fedora org.gnome.Loupe
    flatpak install -y fedora org.gnome.NautilusPreviewer
    flatpak install -y flathub com.mattjakeman.ExtensionManager
    ;;
  esac

  # Set default applications
  if command -v xdg-settings >/dev/null 2>&1; then
    log "flatpak" "setting default web browser"
    xdg-settings set default-web-browser com.vivaldi.Vivaldi.desktop
  fi

  log "flatpak" "installation complete"
}

update() {
  if ! command -v flatpak >/dev/null 2>&1; then
    log "flatpak" "not installed"
    return 1
  fi

  log "flatpak" "updating flatpak applications"
  flatpak update -y

  log "flatpak" "cleaning up unused runtimes"
  flatpak uninstall --unused -y
}

uninstall() {
  if ! command -v flatpak >/dev/null 2>&1; then
    log "flatpak" "not installed"
    return 0
  fi

  log "flatpak" "uninstalling all flatpak applications"
  flatpak uninstall --all -y

  log "flatpak" "removing Flathub remote"
  flatpak remote-delete flathub --force
}

status() {
  if ! command -v flatpak >/dev/null 2>&1; then
    log "flatpak" "flatpak not available"
    return 0
  fi

  local version
  version=$(flatpak --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
  log "flatpak" "version: ${version}"

  local app_count
  app_count=$(flatpak list --app 2>/dev/null | wc -l)
  log "flatpak" "installed applications: ${app_count}"
}

# Handle command line arguments
action="${1:-status}"
case "${action}" in
install | update | uninstall | status)
  "${action}"
  ;;
*)
  echo "Usage: $0 {install|update|uninstall|status}" >&2
  exit 1
  ;;
esac
