#!/bin/sh

# dmg.sh - DMG installer backend for app management
#
# This library provides functions for installing macOS applications from DMG files.
# It is designed to be sourced by the main app.sh module.
#
# Functions:
#   dmg_install <url> <app_name> <team_id> <install_dir>
#   dmg_verify <app_path> <team_id>
#   dmg_uninstall <app_path>
#
# Dependencies:
#   - curl
#   - hdiutil
#   - ditto
#   - codesign (for verification)
#   - log library (for logging)

# Check if required tools are available
dmg_check_deps() {
  local missing=""
  for tool in curl hdiutil ditto; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing="${missing}${missing:+, }${tool}"
    fi
  done

  if [ -n "$missing" ]; then
    log error "missing tools" "$missing"
    return 1
  fi

  return 0
}

# Verify code signature and team ID
dmg_verify() {
  local app_path="$1"
  local team_id="$2"

  if [ ! -d "$app_path" ]; then
    log error "app not found" "$app_path"
    return 1
  fi

  if ! command -v codesign >/dev/null 2>&1; then
    log warn "codesign unavailable" "Cannot verify signature"
    return 0
  fi

  # Get Team ID from codesign
  local found_team_id
  found_team_id=$(codesign -dv --verbose=2 "$app_path" 2>&1 | awk -F= '/^TeamIdentifier=/{print $2; exit}')

  if [ -z "$team_id" ]; then
    # No team ID specified, just log what we found
    log info "team id" "${found_team_id:-not found}"
    return 0
  fi

  # Verify team ID matches
  if [ "$found_team_id" != "$team_id" ]; then
    log error "team id mismatch" "Expected: $team_id, Found: ${found_team_id:-unknown}"
    return 1
  fi

  log info "team id verified" "$team_id"
  return 0
}

# Install application from DMG
dmg_install() {
  local dmg_url="$1"
  local app_name="$2"
  local team_id="${3:-}"
  local install_dir="${4:-/Applications}"
  local forced_app_name="${5:-}"

  # Check dependencies
  if ! dmg_check_deps; then
    return 1
  fi

  # Determine expected app path
  local expected_app_name="${forced_app_name:-$app_name}"
  local app_path="${install_dir}/${expected_app_name}"

  # Check if already installed
  if [ -d "$app_path" ]; then
    log info "$(basename "$app_path" .app)" "already installed, skipping"
    return 0
  fi

  # Determine if we need sudo
  local use_sudo=""
  if [ "$install_dir" = "/Applications" ] && [ ! -w "$install_dir" ]; then
    use_sudo="sudo"
  fi

  # Create install directory if needed
  if [ -z "$use_sudo" ]; then
    mkdir -p "$install_dir"
  fi

  # Create temporary directory
  local tmpdir
  tmpdir=$(mktemp -d -t dmginstall.XXXXXX)

  # Cleanup function
  cleanup_dmg() {
    if [ -n "${mount_point:-}" ] && [ -d "${mount_point:-}" ]; then
      hdiutil detach "${mount_point}" -quiet 2>/dev/null || true
    fi
    if [ -d "$tmpdir" ]; then
      rm -rf "$tmpdir"
    fi
  }
  trap cleanup_dmg EXIT INT TERM

  local dmg_path="${tmpdir}/app.dmg"

  log info "downloading" "DMG from URL..."
  if ! curl -fL --retry 3 --retry-delay 2 --max-time 600 -o "$dmg_path" "$dmg_url"; then
    log error "download failed" "$dmg_url"
    cleanup_dmg
    return 1
  fi

  log info "attaching" "DMG..."
  local mount_point="${tmpdir}/mnt"
  mkdir -p "$mount_point"
  if ! hdiutil attach -nobrowse -readonly -mountpoint "$mount_point" "$dmg_path" >/dev/null 2>&1; then
    log error "mount failed" "Could not attach DMG"
    cleanup_dmg
    return 1
  fi

  # Find the app
  local app_path=""
  local pkg_path=""

  if [ -n "$forced_app_name" ] && [ -e "${mount_point}/${forced_app_name}" ]; then
    app_path="${mount_point}/${forced_app_name}"
  else
    # Find top-level .app
    app_path=$(find "$mount_point" -maxdepth 1 -type d -name "*.app" -print -quit 2>/dev/null || true)
  fi

  if [ -z "$app_path" ]; then
    # Look for .pkg as fallback
    pkg_path=$(find "$mount_point" -maxdepth 2 -type f -name "*.pkg" -print -quit 2>/dev/null || true)
  fi

  if [ -z "$app_path" ] && [ -z "$pkg_path" ]; then
    log error "no app found" "No .app or .pkg found in DMG"
    cleanup_dmg
    return 1
  fi

  # Handle PKG installer
  if [ -n "$pkg_path" ]; then
    log info "found pkg" "$(basename "$pkg_path")"
    if [ -n "$use_sudo" ] || [ "$(id -u)" -eq 0 ]; then
      ${use_sudo} installer -pkg "$pkg_path" -target /
      log info "installed" "$(basename "$pkg_path")"
      cleanup_dmg
      return 0
    else
      log error "pkg requires sudo" "PKG installers require admin privileges"
      cleanup_dmg
      return 1
    fi
  fi

  # Handle .app bundle
  local found_app_name
  found_app_name=$(basename "$app_path")
  local dest_path="${install_dir}/${found_app_name}"

  # Handle existing installation
  if [ -e "$dest_path" ]; then
    log info "existing app" "$dest_path"

    if [ -z "$use_sudo" ]; then
      # User install - move to Trash
      if command -v osascript >/dev/null 2>&1; then
        if ! osascript -e "tell application \"Finder\" to delete POSIX file \"$dest_path\"" 2>/dev/null; then
          log warn "trash failed" "Removing directly..."
          rm -rf "$dest_path"
        fi
      else
        rm -rf "$dest_path"
      fi
    else
      # System install - backup with timestamp
      local ts
      ts=$(date +%Y%m%d-%H%M%S)
      local backup_path="${dest_path%.app}.backup-${ts}.app"
      log info "backing up" "$(basename "$backup_path")"
      ${use_sudo} mv "$dest_path" "$backup_path"
    fi
  fi

  # Copy app to destination
  log info "copying" "${found_app_name} to ${install_dir}..."
  if [ -n "$use_sudo" ]; then
    if ! ${use_sudo} ditto "$app_path" "$dest_path"; then
      log error "copy failed" "Could not copy application"
      cleanup_dmg
      return 1
    fi
    ${use_sudo} xattr -d com.apple.quarantine "$dest_path" 2>/dev/null || true
  else
    if ! ditto "$app_path" "$dest_path"; then
      log error "copy failed" "Could not copy application"
      cleanup_dmg
      return 1
    fi
    xattr -d com.apple.quarantine "$dest_path" 2>/dev/null || true
  fi

  # Verify Team ID if specified
  if [ -n "$team_id" ]; then
    log info "verifying" "Code signature..."
    if ! dmg_verify "$dest_path" "$team_id"; then
      log warn "verification failed" "App installed but signature check failed"
    fi
  fi

  # Gatekeeper assessment (informational, non-blocking)
  /usr/sbin/spctl --assess --type execute "$dest_path" >/dev/null 2>&1 || true

  # Register with Launch Services
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$dest_path" >/dev/null 2>&1 || true

  log info "installed" "$dest_path"

  # Cleanup
  log info "cleaning up" "Detaching DMG..."
  hdiutil detach "$mount_point" -quiet 2>/dev/null || true
  cleanup_dmg
  trap - EXIT INT TERM

  return 0
}

# Uninstall application
dmg_uninstall() {
  local app_path="$1"
  local use_trash="${2:-true}"

  if [ ! -e "$app_path" ]; then
    log error "app not found" "$app_path"
    return 1
  fi

  log info "uninstalling" "$app_path"

  # Determine if we need sudo
  local parent_dir
  parent_dir=$(dirname "$app_path")
  local use_sudo=""
  if [ ! -w "$parent_dir" ]; then
    use_sudo="sudo"
  fi

  if [ -z "$use_sudo" ] && [ "$use_trash" = "true" ]; then
    # User install - try to move to Trash
    if command -v osascript >/dev/null 2>&1; then
      if osascript -e "tell application \"Finder\" to delete POSIX file \"$app_path\"" 2>/dev/null; then
        log info "moved to trash" "$(basename "$app_path")"
        return 0
      else
        log warn "trash failed" "Removing directly..."
      fi
    fi
  fi

  # Direct removal
  if [ -n "$use_sudo" ]; then
    ${use_sudo} rm -rf "$app_path"
  else
    rm -rf "$app_path"
  fi

  log info "uninstalled" "$(basename "$app_path")"
  return 0
}

# Get status of installed app
dmg_status() {
  local app_path="$1"
  local team_id="${2:-}"

  local app_name
  app_name=$(basename "$app_path" .app)

  if [ ! -d "$app_path" ]; then
    log_status "$app_name" "dmg" "not installed" "warn"
    return 0
  fi

  # Check Team ID if specified
  if [ -n "$team_id" ]; then
    if dmg_verify "$app_path" "$team_id" >/dev/null 2>&1; then
      log_status "$app_name" "dmg" "installed, signature verified"
      return 0
    else
      log_status "$app_name" "dmg" "signature verification failed" "error"
      return 1
    fi
  fi

  log_status "$app_name" "dmg" "installed"
  return 0
}
