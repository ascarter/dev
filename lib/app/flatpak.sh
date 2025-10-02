#!/bin/sh

# flatpak.sh - Flatpak installer backend for app management
#
# This library provides functions for installing Linux applications from Flathub
# using Flatpak. It is designed to be sourced by the main app.sh module.
#
# Functions:
#   flatpak_install <app_id> <remote>
#   flatpak_uninstall <app_id>
#   flatpak_status <app_id>
#   flatpak_update <app_id>
#
# Dependencies:
#   - flatpak
#   - log library (for logging)

# Check if flatpak is available
flatpak_check_deps() {
  if ! command -v flatpak >/dev/null 2>&1; then
    log error "flatpak unavailable" "Flatpak is not installed on this system"
    return 1
  fi
  return 0
}

# Ensure Flathub remote is configured
flatpak_ensure_remote() {
  local remote="${1:-flathub}"

  if ! flatpak_check_deps; then
    return 1
  fi

  # Check if remote already exists
  if flatpak remotes 2>/dev/null | grep -q "^${remote}"; then
    return 0
  fi

  log info "adding remote" "$remote"

  case "$remote" in
  flathub)
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    ;;
  fedora)
    # Fedora remote is usually pre-configured on Fedora systems
    log warn "fedora remote" "Should be pre-configured on Fedora systems"
    return 1
    ;;
  *)
    log error "unknown remote" "$remote"
    return 1
    ;;
  esac

  return 0
}

# Install Flatpak application
# Args:
#   $1 - Application ID (e.g., "com.github.tchx84.Flatseal")
#   $2 - Remote name (default: "flathub")
flatpak_install() {
  local app_id="$1"
  local remote="${2:-flathub}"

  # Check dependencies
  if ! flatpak_check_deps; then
    return 1
  fi

  # Ensure remote is configured
  if ! flatpak_ensure_remote "$remote"; then
    return 1
  fi

  log info "installing" "$app_id from $remote"

  # Check if already installed
  if flatpak list --app 2>/dev/null | grep -q "^${app_id}"; then
    log info "already installed" "$app_id"
    return 0
  fi

  # Install application
  if ! flatpak install -y "$remote" "$app_id" 2>&1 | grep -v "^$"; then
    log error "installation failed" "$app_id"
    return 1
  fi

  log info "installed" "$app_id"
  return 0
}

# Uninstall Flatpak application
# Args:
#   $1 - Application ID
flatpak_uninstall() {
  local app_id="$1"

  if ! flatpak_check_deps; then
    return 1
  fi

  log info "uninstalling" "$app_id"

  # Check if installed
  if ! flatpak list --app 2>/dev/null | grep -q "^${app_id}"; then
    log info "not installed" "$app_id"
    return 0
  fi

  # Uninstall application
  if ! flatpak uninstall -y "$app_id" 2>&1 | grep -v "^$"; then
    log error "uninstall failed" "$app_id"
    return 1
  fi

  log info "uninstalled" "$app_id"
  return 0
}

# Get status of Flatpak application
# Args:
#   $1 - Application ID
flatpak_status() {
  local app_id="$1"

  if ! flatpak_check_deps; then
    return 1
  fi

  # Check if installed
  if flatpak list --app 2>/dev/null | grep -q "^${app_id}"; then
    local version branch
    version=$(flatpak info "$app_id" 2>/dev/null | awk '/Version:/ {print $2}' || echo "unknown")
    branch=$(flatpak info "$app_id" 2>/dev/null | awk '/Branch:/ {print $2}' || echo "unknown")

    log info "$app_id" "installed (version: $version, branch: $branch)"
    return 0
  else
    log info "$app_id" "not installed"
    return 1
  fi
}

# Update Flatpak application
# Args:
#   $1 - Application ID
flatpak_update() {
  local app_id="$1"

  if ! flatpak_check_deps; then
    return 1
  fi

  log info "updating" "$app_id"

  # Check if installed
  if ! flatpak list --app 2>/dev/null | grep -q "^${app_id}"; then
    log warn "not installed" "$app_id - cannot update"
    return 1
  fi

  # Update application
  if ! flatpak update -y "$app_id" 2>&1 | grep -v "^$"; then
    log error "update failed" "$app_id"
    return 1
  fi

  log info "updated" "$app_id"
  return 0
}

# Update all Flatpak applications
flatpak_update_all() {
  if ! flatpak_check_deps; then
    return 1
  fi

  log info "updating" "all Flatpak applications"

  if ! flatpak update -y 2>&1 | grep -v "^$"; then
    log error "update failed" "could not update applications"
    return 1
  fi

  log info "updated" "all applications"
  return 0
}
