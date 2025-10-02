#!/bin/sh

# app.sh - Application management module for dev
#
# This module provides unified application management across different
# installer types (DMG, UBI, Flatpak, etc.) using manifest files.
#
# Usage (via dev command):
#   dev app install <name>           Install specific app from manifest
#   dev app install --all            Install all apps in manifest
#   dev app uninstall <name>         Uninstall specific app
#   dev app status <name>            Show status of specific app
#   dev app status --all             Show status of all apps
#   dev app update <name>            Update specific app
#   dev app update --all             Update all apps
#   dev app list                     List all apps in manifest
#
# Supported installer types:
#   - dmg: macOS DMG installers
#   - ubi: GitHub releases via Universal Binary Installer
#   - flatpak: Linux applications via Flatpak

# Ensure DEV_HOME is set
if [ -z "${DEV_HOME:-}" ]; then
  DEV_HOME="$(cd "$(dirname "$0")/.." && pwd)"
fi

# Source required libraries
. "${DEV_HOME}/lib/toml.sh"
. "${DEV_HOME}/lib/app/dmg.sh"
. "${DEV_HOME}/lib/app/ubi.sh"
. "${DEV_HOME}/lib/app/flatpak.sh"

# Default values
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}

# Get manifest file(s) for the current platform
# Returns: Space-separated list of manifest files (cli.toml + platform.toml)
app_get_manifest() {
  local manifest_file="${1:-}"

  # If manifest file specified, use it
  if [ -n "$manifest_file" ]; then
    if [ -f "$manifest_file" ]; then
      printf '%s' "$manifest_file"
      return 0
    else
      log error "manifest not found" "$manifest_file"
      return 1
    fi
  fi

  # Auto-detect platform
  local platform=""
  case "$(uname -s)" in
  Darwin) platform="macos" ;;
  Linux) platform="linux" ;;
  *)
    log error "unsupported platform" "$(uname -s)"
    return 1
    ;;
  esac

  # Build list of manifests to load (cli.toml + platform.toml)
  local manifests=""
  local cli_manifest="${DEV_HOME}/hosts/cli.toml"
  local platform_manifest="${DEV_HOME}/hosts/${platform}.toml"

  # Add cli manifest if it exists
  if [ -f "$cli_manifest" ]; then
    manifests="$cli_manifest"
  fi

  # Add platform manifest if it exists
  if [ -f "$platform_manifest" ]; then
    if [ -n "$manifests" ]; then
      manifests="$manifests $platform_manifest"
    else
      manifests="$platform_manifest"
    fi
  fi

  # Ensure at least one manifest exists
  if [ -z "$manifests" ]; then
    log error "no manifests found" "Expected cli.toml or ${platform}.toml in hosts/"
    return 1
  fi

  printf '%s' "$manifests"
  return 0
}

# Parse app configuration from manifest(s)
# Supports multiple manifests - later ones override earlier ones
# Returns: value for the specified key
app_get_config() {
  local manifests="$1"
  local app_name="$2"
  local var_name="$3"

  local result=""

  # Check each manifest file
  for manifest in $manifests; do
    local value
    value=$(toml_get "$manifest" "$app_name" "$var_name")

    # If we found a value, use it (later manifests override earlier ones)
    if [ -n "$value" ]; then
      result="$value"
    fi
  done

  printf '%s' "$result"
}

# Install a single app
app_install_one() {
  local manifest="$1"
  local app_name="$2"

  log info "=== $app_name ===" ""

  # Get installer type
  local installer
  installer=$(app_get_config "$manifest" "$app_name" "installer")

  if [ -z "$installer" ]; then
    log error "no installer" "App $app_name has no installer type defined"
    return 1
  fi

  # Dispatch to appropriate installer
  case "$installer" in
  dmg)
    app_install_dmg "$manifest" "$app_name"
    ;;
  ubi)
    app_install_ubi "$manifest" "$app_name"
    ;;
  flatpak)
    app_install_flatpak "$manifest" "$app_name"
    ;;
  *)
    log error "unknown installer" "$installer"
    return 1
    ;;
  esac
}

# Install DMG-based application
app_install_dmg() {
  local manifest="$1"
  local app_name="$2"

  local url app team_id install_dir
  url=$(app_get_config "$manifest" "$app_name" "url")
  app=$(app_get_config "$manifest" "$app_name" "app")
  team_id=$(app_get_config "$manifest" "$app_name" "team_id")
  install_dir=$(app_get_config "$manifest" "$app_name" "install_dir")

  # Determine install directory
  local user_install
  user_install=$(app_get_config "$manifest" "$app_name" "user")
  if [ -z "$install_dir" ]; then
    if [ "$user_install" = "true" ]; then
      install_dir="$HOME/Applications"
    else
      install_dir="/Applications"
    fi
  fi

  # Validate required fields
  if [ -z "$url" ]; then
    log error "missing config" "url is required for DMG installer"
    return 1
  fi

  if [ -z "$app" ]; then
    log error "missing config" "app name is required for DMG installer"
    return 1
  fi

  # Install using dmg backend
  dmg_install "$url" "$app" "$team_id" "$install_dir"
}

# Install UBI-based tool
app_install_ubi() {
  local manifest="$1"
  local app_name="$2"

  local project bin_name install_dir extract_all symlinks
  project=$(app_get_config "$manifest" "$app_name" "project")
  bin_name=$(app_get_config "$manifest" "$app_name" "bin_name")
  install_dir=$(app_get_config "$manifest" "$app_name" "install_dir")
  extract_all=$(app_get_config "$manifest" "$app_name" "extract_all")
  symlinks=$(app_get_config "$manifest" "$app_name" "symlinks")

  # Validate required fields
  if [ -z "$project" ]; then
    log error "missing config" "project is required for UBI installer"
    return 1
  fi

  # Default bin_name to app_name if not specified
  if [ -z "$bin_name" ]; then
    bin_name="$app_name"
  fi

  # Default extract_all
  if [ -z "$extract_all" ]; then
    extract_all="false"
  fi

  # Smart default for install directory based on extract_all
  if [ -z "$install_dir" ]; then
    if [ "$extract_all" = "true" ]; then
      # For extract_all, use dedicated directory in XDG_DATA_HOME based on app name
      install_dir="${XDG_DATA_HOME}/${app_name}"
    else
      # For single binary, use XDG_BIN_HOME
      install_dir="${XDG_BIN_HOME}"
    fi
  fi

  # Install using ubi backend
  ubi_install "$project" "$bin_name" "$install_dir" "$extract_all" "$symlinks"
}

# Update UBI-based tool
app_update_ubi() {
  local manifest="$1"
  local app_name="$2"

  local project bin_name install_dir extract_all symlinks
  project=$(app_get_config "$manifest" "$app_name" "project")
  bin_name=$(app_get_config "$manifest" "$app_name" "bin_name")
  install_dir=$(app_get_config "$manifest" "$app_name" "install_dir")
  extract_all=$(app_get_config "$manifest" "$app_name" "extract_all")
  symlinks=$(app_get_config "$manifest" "$app_name" "symlinks")

  # Validate required fields
  if [ -z "$project" ]; then
    log error "missing config" "project is required for UBI installer"
    return 1
  fi

  # Default bin_name to app_name if not specified
  if [ -z "$bin_name" ]; then
    bin_name="$app_name"
  fi

  # Default extract_all
  if [ -z "$extract_all" ]; then
    extract_all="false"
  fi

  # Smart default for install directory based on extract_all
  if [ -z "$install_dir" ]; then
    if [ "$extract_all" = "true" ]; then
      # For extract_all, use dedicated directory in XDG_DATA_HOME based on app name
      install_dir="${XDG_DATA_HOME}/${app_name}"
    else
      # For single binary, use XDG_BIN_HOME
      install_dir="${XDG_BIN_HOME}"
    fi
  fi

  # Update using ubi backend
  ubi_update "$project" "$bin_name" "$install_dir" "$extract_all" "$symlinks"
}

# Install Flatpak application
app_install_flatpak() {
  local manifest="$1"
  local app_name="$2"

  local app_id remote
  app_id=$(app_get_config "$manifest" "$app_name" "app_id")
  remote=$(app_get_config "$manifest" "$app_name" "remote")

  # Validate required fields
  if [ -z "$app_id" ]; then
    log error "missing config" "app_id is required for Flatpak installer"
    return 1
  fi

  # Default remote
  if [ -z "$remote" ]; then
    remote="flathub"
  fi

  # Install using flatpak backend
  flatpak_install "$app_id" "$remote"
}

# Uninstall a single app
app_uninstall_one() {
  local manifest="$1"
  local app_name="$2"

  log info "=== $app_name ===" ""

  # Get installer type
  local installer
  installer=$(app_get_config "$manifest" "$app_name" "installer")

  if [ -z "$installer" ]; then
    log error "no installer" "App $app_name has no installer type defined"
    return 1
  fi

  # Dispatch to appropriate installer
  case "$installer" in
  dmg)
    app_uninstall_dmg "$manifest" "$app_name"
    ;;
  ubi)
    app_uninstall_ubi "$manifest" "$app_name"
    ;;
  flatpak)
    app_uninstall_flatpak "$manifest" "$app_name"
    ;;
  *)
    log error "unknown installer" "$installer"
    return 1
    ;;
  esac
}

# Uninstall DMG-based application
app_uninstall_dmg() {
  local manifest="$1"
  local app_name="$2"

  local app install_dir
  app=$(app_get_config "$manifest" "$app_name" "app")
  install_dir=$(app_get_config "$manifest" "$app_name" "install_dir")

  # Determine install directory
  local user_install
  user_install=$(app_get_config "$manifest" "$app_name" "user")
  if [ -z "$install_dir" ]; then
    if [ "$user_install" = "true" ]; then
      install_dir="$HOME/Applications"
    else
      install_dir="/Applications"
    fi
  fi

  # Validate required fields
  if [ -z "$app" ]; then
    log error "missing config" "app name is required"
    return 1
  fi

  local app_path="${install_dir}/${app}"
  dmg_uninstall "$app_path" "true"
}

# Uninstall UBI-based tool
app_uninstall_ubi() {
  local manifest="$1"
  local app_name="$2"

  local bin_name install_dir extract_all symlinks
  bin_name=$(app_get_config "$manifest" "$app_name" "bin_name")
  install_dir=$(app_get_config "$manifest" "$app_name" "install_dir")
  extract_all=$(app_get_config "$manifest" "$app_name" "extract_all")
  symlinks=$(app_get_config "$manifest" "$app_name" "symlinks")

  # Default bin_name to app_name if not specified
  if [ -z "$bin_name" ]; then
    bin_name="$app_name"
  fi

  # Default extract_all
  if [ -z "$extract_all" ]; then
    extract_all="false"
  fi

  # Smart default for install directory based on extract_all
  if [ -z "$install_dir" ]; then
    if [ "$extract_all" = "true" ]; then
      # For extract_all, use dedicated directory in XDG_DATA_HOME based on app name
      install_dir="${XDG_DATA_HOME}/${app_name}"
    else
      # For single binary, use XDG_BIN_HOME
      install_dir="${XDG_BIN_HOME}"
    fi
  fi

  ubi_uninstall "$install_dir" "$bin_name" "$symlinks"
}

# Uninstall Flatpak application
app_uninstall_flatpak() {
  local manifest="$1"
  local app_name="$2"

  local app_id
  app_id=$(app_get_config "$manifest" "$app_name" "app_id")

  # Validate required fields
  if [ -z "$app_id" ]; then
    log error "missing config" "app_id is required"
    return 1
  fi

  flatpak_uninstall "$app_id"
}

# Get status of a single app
app_status_one() {
  local manifest="$1"
  local app_name="$2"

  # Get installer type
  local installer
  installer=$(app_get_config "$manifest" "$app_name" "installer")

  if [ -z "$installer" ]; then
    log error "no installer" "App $app_name has no installer type defined"
    return 1
  fi

  # Dispatch to appropriate installer
  case "$installer" in
  dmg)
    app_status_dmg "$manifest" "$app_name"
    ;;
  ubi)
    app_status_ubi "$manifest" "$app_name"
    ;;
  flatpak)
    app_status_flatpak "$manifest" "$app_name"
    ;;
  *)
    log error "unknown installer" "$installer"
    return 1
    ;;
  esac
}

# Get status of DMG-based application
app_status_dmg() {
  local manifest="$1"
  local app_name="$2"

  local app install_dir team_id
  app=$(app_get_config "$manifest" "$app_name" "app")
  install_dir=$(app_get_config "$manifest" "$app_name" "install_dir")
  team_id=$(app_get_config "$manifest" "$app_name" "team_id")

  # Determine install directory
  local user_install
  user_install=$(app_get_config "$manifest" "$app_name" "user")
  if [ -z "$install_dir" ]; then
    if [ "$user_install" = "true" ]; then
      install_dir="$HOME/Applications"
    else
      install_dir="/Applications"
    fi
  fi

  # Validate required fields
  if [ -z "$app" ]; then
    log error "missing config" "app name is required"
    return 1
  fi

  local app_path="${install_dir}/${app}"
  dmg_status "$app_path" "$team_id"
}

# Get status of UBI-based tool
app_status_ubi() {
  local manifest="$1"
  local app_name="$2"

  local bin_name install_dir extract_all status_cmd
  bin_name=$(app_get_config "$manifest" "$app_name" "bin_name")
  install_dir=$(app_get_config "$manifest" "$app_name" "install_dir")
  extract_all=$(app_get_config "$manifest" "$app_name" "extract_all")
  status_cmd=$(app_get_config "$manifest" "$app_name" "status_cmd")

  # Default bin_name to app_name if not specified
  if [ -z "$bin_name" ]; then
    bin_name="$app_name"
  fi

  # Default extract_all
  if [ -z "$extract_all" ]; then
    extract_all="false"
  fi

  # Smart default for install directory based on extract_all
  if [ -z "$install_dir" ]; then
    if [ "$extract_all" = "true" ]; then
      # For extract_all, use dedicated directory in XDG_DATA_HOME based on app name
      install_dir="${XDG_DATA_HOME}/${app_name}"
    else
      # For single binary, use XDG_BIN_HOME
      install_dir="${XDG_BIN_HOME}"
    fi
  fi

  ubi_status "$install_dir" "$bin_name" "$extract_all" "$status_cmd"
}

# Get status of Flatpak application
app_status_flatpak() {
  local manifest="$1"
  local app_name="$2"

  local app_id
  app_id=$(app_get_config "$manifest" "$app_name" "app_id")

  # Validate required fields
  if [ -z "$app_id" ]; then
    log error "missing config" "app_id is required"
    return 1
  fi

  flatpak_status "$app_id"
}

# Update a single app
app_update_one() {
  local manifest="$1"
  local app_name="$2"

  log info "=== $app_name ===" ""

  # Get installer type
  local installer
  installer=$(app_get_config "$manifest" "$app_name" "installer")

  if [ -z "$installer" ]; then
    log error "no installer" "App $app_name has no installer type defined"
    return 1
  fi

  # Check if app supports auto-update
  local auto_update
  auto_update=$(app_get_config "$manifest" "$app_name" "auto_update")
  if [ "$auto_update" = "true" ]; then
    log info "auto-update" "App has built-in auto-update, skipping"
    return 0
  fi

  # Dispatch to appropriate installer (most just reinstall)
  case "$installer" in
  dmg)
    app_install_dmg "$manifest" "$app_name"
    ;;
  ubi)
    app_update_ubi "$manifest" "$app_name"
    ;;
  flatpak)
    local app_id
    app_id=$(app_get_config "$manifest" "$app_name" "app_id")
    if [ -n "$app_id" ]; then
      flatpak_update "$app_id"
    else
      log error "missing config" "app_id is required"
      return 1
    fi
    ;;
  *)
    log error "unknown installer" "$installer"
    return 1
    ;;
  esac
}

# List all apps in manifest(s)
app_list() {
  local manifests="$1"

  log info "apps in manifests" "$manifests"
  printf '\n'

  # Collect all unique sections from all manifests
  local sections=""
  for manifest in $manifests; do
    sections="$sections $(toml_sections "$manifest")"
  done

  # Remove duplicates and sort
  sections=$(printf '%s\n' $sections | sort -u)

  # Display each app
  printf '%s\n' "$sections" | while read -r section; do
    [ -z "$section" ] && continue
    local installer
    installer=$(app_get_config "$manifests" "$section" "installer")

    if [ -n "$installer" ]; then
      printf '  %-30s [%s]\n' "$section" "$installer"
    fi
  done

  printf '\n'
}

# Process all apps (for --all flag)
app_process_all() {
  local manifests="$1"
  local action="$2"

  local processed=0
  local failed=0

  # Collect all unique sections from all manifests
  local sections=""
  for manifest in $manifests; do
    sections="$sections $(toml_sections "$manifest")"
  done

  # Remove duplicates and convert to array-like iteration
  sections=$(printf '%s\n' $sections | sort -u)

  # Process each section (avoid subshell to preserve counters)
  local section
  local installed=0
  local not_installed=0

  for section in $sections; do
    [ -z "$section" ] && continue
    local installer
    installer=$(app_get_config "$manifests" "$section" "installer")

    # Skip non-app sections
    if [ -z "$installer" ]; then
      continue
    fi

    # For status action, count installed vs not installed
    if [ "$action" = "status" ]; then
      # Capture output to check if installed
      local status_output
      status_output=$("app_${action}_one" "$manifests" "$section" 2>&1)
      local status_code=$?

      # Print the output
      printf '%s\n' "$status_output"

      # Count based on output content
      if printf '%s' "$status_output" | grep -q "not installed"; then
        not_installed=$((not_installed + 1))
      else
        installed=$((installed + 1))
      fi

      # Track failures (errors, not just uninstalled)
      if [ $status_code -ne 0 ]; then
        failed=$((failed + 1))
      fi

      processed=$((processed + 1))
    else
      # For other actions, just run and track success/failure
      if "app_${action}_one" "$manifests" "$section"; then
        processed=$((processed + 1))
      else
        failed=$((failed + 1))
      fi
    fi
  done

  # Report summary based on action
  if [ "$action" = "status" ]; then
    # Build summary message
    local summary="$installed installed, $not_installed not installed"
    if [ "$failed" -gt 0 ]; then
      summary="$summary, $failed error"
      if [ "$failed" -gt 1 ]; then
        summary="${summary}s"
      fi
    fi
    log info "summary" "$summary"
    [ "$failed" -gt 0 ] && return 1
  else
    # For install/uninstall/update, show processed/failed
    log info "completed" "$processed apps processed"
    if [ "$failed" -gt 0 ]; then
      log error "failures" "$failed apps failed"
      return 1
    fi
  fi

  return 0
}

# Main app command dispatcher
app_main() {
  if [ $# -eq 0 ]; then
    app_usage
    return 1
  fi

  local action="$1"
  shift

  case "$action" in
  install | uninstall | status | update)
    app_action "$action" "$@"
    ;;
  list)
    app_action_list "$@"
    ;;
  -h | --help | help)
    app_usage
    return 0
    ;;
  *)
    log error "unknown action" "$action"
    app_usage
    return 1
    ;;
  esac
}

# Handle install/uninstall/status/update actions
app_action() {
  local action="$1"
  shift

  local manifest_file=""
  local app_name=""
  local all_flag=false

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
    --file)
      if [ $# -lt 2 ]; then
        log error "missing argument" "--file requires an argument"
        return 1
      fi
      manifest_file="$2"
      shift 2
      ;;
    -*)
      log error "unknown option" "$1"
      return 1
      ;;
    *)
      if [ -z "$app_name" ]; then
        app_name="$1"
      else
        log error "unexpected argument" "$1"
        return 1
      fi
      shift
      ;;
    esac
  done

  # Get manifest(s)
  local manifests
  if ! manifests=$(app_get_manifest "$manifest_file"); then
    return 1
  fi

  # Process apps - default to all if no app specified
  if [ -n "$app_name" ]; then
    "app_${action}_one" "$manifests" "$app_name"
  else
    app_process_all "$manifests" "$action"
  fi
}

# Handle list action
app_action_list() {
  local manifest_file=""

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
    --file)
      if [ $# -lt 2 ]; then
        log error "missing argument" "--file requires an argument"
        return 1
      fi
      manifest_file="$2"
      shift 2
      ;;
    -*)
      log error "unknown option" "$1"
      return 1
      ;;
    *)
      log error "unexpected argument" "$1"
      return 1
      ;;
    esac
  done

  # Get manifest(s)
  local manifests
  if ! manifests=$(app_get_manifest "$manifest_file"); then
    return 1
  fi

  app_list "$manifests"
}

# Usage information
app_usage() {
  cat <<'EOF'
Usage: dev app <action> [options] [name]

Actions:
  install [name]        Install app(s) from manifest (all if no name)
  uninstall [name]      Uninstall app(s) (all if no name)
  status [name]         Show status of app(s) (all if no name)
  update [name]         Update app(s) (all if no name)
  list                  List all apps in manifest

Options:
  --file <path>         Use specific manifest file (default: auto-detect)

Examples:
  dev app install ghostty
  dev app status
  dev app update helix
  dev app list --file custom.toml

Supported installer types:
  dmg       - macOS DMG installers
  ubi       - GitHub releases (cross-platform)
  flatpak   - Linux Flatpak applications
EOF
}
