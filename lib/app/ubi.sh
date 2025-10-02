#!/bin/sh

# ubi.sh - UBI (Universal Binary Installer) backend for app management
#
# This library provides functions for installing CLI tools from GitHub releases
# using ubi. It is designed to be sourced by the main app.sh module.
#
# Functions:
#   ubi_install <project> <bin_name> <install_dir> [extract_all] [symlinks]
#   ubi_uninstall <install_dir> <bin_name> [symlinks]
#   ubi_status <install_dir> <bin_name> <extract_all> [status_cmd]
#
# Notes:
#   - bin_name: Only needed when extract_all=false and binary name differs from section name
#   - status_cmd: Use when binary name differs from section name or for non-standard version commands
#
# Dependencies:
#   - ubi (Universal Binary Installer)
#   - log library (for logging)

# Check if ubi is available
ubi_check_deps() {
  if ! command -v ubi >/dev/null 2>&1; then
    log error "ubi not installed" "Install ubi first: dev tool ubi install"
    return 1
  fi
  return 0
}

# Install tool using ubi
# Args:
#   $1 - GitHub project (e.g., "sharkdp/fd")
#   $2 - Binary name (e.g., "fd") - only used by UBI when extract_all=false
#   $3 - Install directory (e.g., "${XDG_BIN_HOME}")
#   $4 - Extract all flag ("true" or "false", default: "false")
#   $5 - Symlinks (newline-separated "src:dest" pairs from TOML array)
#   $6 - Force reinstall ("true" to skip already-installed check)
ubi_install() {
  local project="$1"
  local bin_name="$2"
  local install_dir="$3"
  local extract_all="${4:-false}"
  local symlinks="${5:-}"
  local force="${6:-false}"

  # Check dependencies
  if ! ubi_check_deps; then
    return 1
  fi

  # Expand environment variables in install_dir
  install_dir=$(eval echo "$install_dir")

  # Check if already installed (unless forced)
  if [ "$force" != "true" ]; then
    if [ "$extract_all" = "true" ]; then
      # For extract_all, just check if the install directory exists
      if [ -d "$install_dir" ]; then
        log info "$bin_name" "already installed, skipping"
        return 0
      fi
    else
      # For single binary, check if the binary file exists
      local bin_path="${install_dir}/${bin_name}"
      if [ -f "$bin_path" ] || [ -L "$bin_path" ]; then
        log info "$bin_name" "already installed, skipping"
        return 0
      fi
    fi
  fi

  # Create install directory
  mkdir -p "$install_dir"

  log info "installing" "$bin_name from $project"

  # Build ubi command
  local ubi_cmd="ubi --project \"$project\" --in \"$install_dir\""

  if [ "$extract_all" = "true" ]; then
    ubi_cmd="${ubi_cmd} --extract-all"
  else
    # For single binary mode, specify the executable name
    ubi_cmd="${ubi_cmd} --exe \"$bin_name\""
  fi

  # Execute ubi
  if ! eval "$ubi_cmd"; then
    log error "installation failed" "$bin_name"
    return 1
  fi

  # Handle symlinks if specified
  if [ -n "$symlinks" ]; then
    ubi_create_symlinks "$install_dir" "$symlinks"
  fi

  log info "installed" "$bin_name"
  return 0
}

# Create symlinks for installed tool
# Args:
#   $1 - Base directory
#   $2 - Newline-separated "src:dest" pairs
ubi_create_symlinks() {
  local base_dir="$1"
  local symlinks="$2"

  # Parse symlink definitions
  # Format: newline-separated "src:dest" pairs
  printf '%s\n' "$symlinks" | while IFS= read -r link_def; do
    [ -z "$link_def" ] && continue
    local src="${link_def%%:*}"
    local dest="${link_def##*:}"

    # Expand environment variables
    src=$(eval echo "$src")
    dest=$(eval echo "$dest")

    # Make src absolute if relative
    case "$src" in
    /*) ;;
    *) src="${base_dir}/${src}" ;;
    esac

    # Smart binary detection for extract_all
    # If exact source doesn't exist, look for platform-specific variant (e.g., yq_darwin_arm64)
    if [ ! -e "$src" ]; then
      local src_base
      src_base=$(basename "$src")
      local src_dir
      src_dir=$(dirname "$src")

      # Look for files matching pattern: basename_* (platform-specific binaries)
      local matched_file
      matched_file=$(find "$src_dir" -maxdepth 1 -type f -name "${src_base}_*" 2>/dev/null | head -1)

      if [ -n "$matched_file" ] && [ -f "$matched_file" ]; then
        src="$matched_file"
        log info "auto-detected" "$(basename "$src") for $(basename "$dest")"
      fi
    fi

    # Create destination directory if needed
    local dest_dir
    dest_dir=$(dirname "$dest")
    mkdir -p "$dest_dir"

    # Remove existing symlink or file
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      rm -f "$dest"
    fi

    # Create symlink
    if [ -e "$src" ]; then
      ln -s "$src" "$dest"
      log info "symlink created" "$(basename "$dest") -> $src"
    else
      log warn "symlink source missing" "$src"
    fi
  done
}

# Uninstall tool
# Args:
#   $1 - Install directory
#   $2 - Binary name
#   $3 - Symlinks (newline-separated "src:dest" pairs from TOML array)
ubi_uninstall() {
  local install_dir="$1"
  local bin_name="$2"
  local symlinks="${3:-}"

  # Expand environment variables
  install_dir=$(eval echo "$install_dir")

  log info "uninstalling" "$bin_name"

  # Remove symlinks first
  if [ -n "$symlinks" ]; then
    printf '%s\n' "$symlinks" | while IFS= read -r link_def; do
      [ -z "$link_def" ] && continue
      local dest="${link_def##*:}"
      dest=$(eval echo "$dest")

      if [ -L "$dest" ] || [ -e "$dest" ]; then
        rm -f "$dest"
        log info "removed symlink" "$(basename "$dest")"
      fi
    done
  fi

  # Remove installation directory or binary
  if [ -d "$install_dir" ]; then
    # Check if this looks like a dedicated tool directory
    # (e.g., ~/.local/share/helix) vs a shared bin directory
    local parent_name
    parent_name=$(basename "$install_dir")

    # If directory name matches tool name, remove entire directory
    if [ "$parent_name" = "$bin_name" ] || [ -d "${install_dir}/runtime" ]; then
      rm -rf "$install_dir"
      log info "removed directory" "$install_dir"
    else
      # Shared directory - just remove the binary
      local bin_path="${install_dir}/${bin_name}"
      if [ -f "$bin_path" ]; then
        rm -f "$bin_path"
        log info "removed binary" "$bin_path"
      fi
    fi
  fi

  log info "uninstalled" "$bin_name"
  return 0
}

# Get status of installed tool
# Args:
#   $1 - Install directory
#   $2 - Binary name (used for default status_cmd if not specified)
#   $3 - Extract all flag ("true" or "false")
#   $4 - Status command (optional, defaults to "<bin_name> --version" or "<bin_name> version")
# Notes:
#   - For extract_all=true: Checks if install directory exists
#   - For extract_all=false: Checks if binary file exists in shared directory
#   - status_cmd overrides default version checking commands
ubi_status() {
  local install_dir="$1"
  local bin_name="$2"
  local extract_all="${3:-false}"
  local status_cmd="${4:-}"

  # Expand environment variables
  install_dir=$(eval echo "$install_dir")

  # Check if tool is installed
  # For extract_all=true, check if the install directory exists (dedicated dir)
  # For extract_all=false, check if the binary exists in the shared directory
  if [ "$extract_all" = "true" ]; then
    if [ ! -d "$install_dir" ]; then
      log_status "$bin_name" "ubi" "not installed" "warn"
      return 0
    fi
  else
    local bin_path="${install_dir}/${bin_name}"
    if [ ! -f "$bin_path" ] && [ ! -L "$bin_path" ]; then
      log_status "$bin_name" "ubi" "not installed" "warn"
      return 0
    fi
  fi

  # Determine status command
  if [ -z "$status_cmd" ]; then
    # Try default commands
    if command -v "$bin_name" >/dev/null 2>&1; then
      # Try --version first
      if output=$("$bin_name" --version 2>&1 | head -1) && [ -n "$output" ]; then
        log_status "$bin_name" "ubi" "$output"
        return 0
      # Try version second
      elif output=$("$bin_name" version 2>&1 | head -1) && [ -n "$output" ]; then
        log_status "$bin_name" "ubi" "$output"
        return 0
      else
        log_status "$bin_name" "ubi" "installed"
        return 0
      fi
    else
      log_status "$bin_name" "ubi" "not in PATH" "error"
      return 1
    fi
  else
    # Use custom status command
    if output=$(eval "$status_cmd" 2>&1 | head -1) && [ -n "$output" ]; then
      log_status "$bin_name" "ubi" "$output"
      return 0
    else
      log_status "$bin_name" "ubi" "status check failed" "error"
      return 1
    fi
  fi
}

# Update tool (reinstall)
# Args: same as ubi_install (but force=true is added)
ubi_update() {
  log info "updating" "$2"
  # Call install with force=true (6th parameter)
  ubi_install "$1" "$2" "$3" "$4" "$5" "true"
}
