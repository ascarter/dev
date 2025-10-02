#!/bin/sh

# Flatpak application installer

set -eu

# Source log library for performance
. "$(dirname "$0")/../lib/log.sh"

install() {
  if ! command -v flatpak >/dev/null 2>&1; then
    log info "flatpak" "flatpak not available on this system"
    return 1
  fi

  log info "flatpak" "enabling Flathub remote"
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  log info "flatpak" "updating flatpak repositories"
  flatpak update -y

  log info "flatpak" "installing core applications"
  flatpak install -y flathub com.github.tchx84.Flatseal
  flatpak install -y flathub com.vivaldi.Vivaldi
  flatpak install -y flathub io.github.shiftey.Desktop
  flatpak install -y flathub io.missioncenter.MissionCenter
  flatpak install -y flathub io.podman_desktop.PodmanDesktop
  flatpak install -y flathub org.videolan.VLC

  # Desktop-specific applications
  case "${XDG_CURRENT_DESKTOP:-}" in
  COSMIC)
    log info "flatpak" "installing COSMIC desktop applications"
    flatpak install -y flathub com.jwestall.Forecast
    flatpak install -y flathub dev.deedles.Trayscale
    flatpak install -y flathub dev.edfloreshz.Calculator
    flatpak install -y flathub io.github.cosmic_utils.Examine
    ;;
  GNOME)
    log info "flatpak" "installing GNOME desktop applications"
    flatpak install -y fedora org.gnome.Connections
    flatpak install -y fedora org.gnome.Extensions
    flatpak install -y fedora org.gnome.Loupe
    flatpak install -y fedora org.gnome.NautilusPreviewer
    flatpak install -y flathub com.mattjakeman.ExtensionManager
    ;;
  esac

  # Set default applications
  if command -v xdg-settings >/dev/null 2>&1; then
    log info "flatpak" "setting default web browser"
    xdg-settings set default-web-browser com.vivaldi.Vivaldi.desktop
  fi

  log info "flatpak" "installation complete"
}

update() {
  if ! command -v flatpak >/dev/null 2>&1; then
    log info "flatpak" "not installed"
    return 1
  fi

  log info "flatpak" "updating flatpak applications"
  flatpak update -y

  log info "flatpak" "cleaning up unused runtimes"
  flatpak uninstall --unused -y
}

uninstall() {
  if ! command -v flatpak >/dev/null 2>&1; then
    log info "flatpak" "not installed"
    return 0
  fi

  log info "flatpak" "uninstalling all flatpak applications"
  flatpak uninstall --all -y

  log info "flatpak" "removing Flathub remote"
  flatpak remote-delete flathub --force
}

status() {
  if ! command -v flatpak >/dev/null 2>&1; then
    log info "flatpak" "not available"
    return 0
  fi

  local version app_count
  version=$(flatpak --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
  app_count=$(flatpak list --app 2>/dev/null | wc -l | tr -d ' ')
  log info "flatpak" "${version}, ${app_count} apps"
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
