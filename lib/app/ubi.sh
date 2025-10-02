#!/bin/sh

# ubi.sh - UBI (Universal Binary Installer) backend for app management
#
# This library provides functions for installing CLI tools from GitHub releases
# using ubi. All installations go to $XDG_DATA_HOME/<app> for consistency.
#
# Functions:
#   ubi_install <app_name> <project> <bin> <symlinks> [force]
#   ubi_uninstall <app_name> <bin> <symlinks>
#   ubi_status <app_name> <bin> [status_cmd]
#   ubi_update <app_name> <project> <bin> <symlinks>
#
# Notes:
#   - All tools extract to $XDG_DATA_HOME/<app_name>
#   - bin is an array of binaries to symlink to $XDG_BIN_HOME
#   - bin format: "relative/path/to/binary" or "path/to/binary:alias"
#   - Default bin: ["<app_name>"] (symlinks <app_name> from root to $XDG_BIN_HOME/<app_name>)
#   - symlinks is for supplementary files (man pages, completions, etc.)
#   - symlinks format: "src:dest" with environment variable expansion
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
#   $1 - App name (used for install directory)
#   $2 - GitHub project (e.g., "sharkdp/fd")
#   $3 - Bin array (newline-separated binary paths, optional :alias suffix)
#   $4 - Symlinks (newline-separated "src:dest" pairs for supplementary files)
#   $5 - Force reinstall ("true" to skip already-installed check)
ubi_install() {
  local app_name="$1"
  local project="$2"
  local bin="${3:-}"
  local symlinks="${4:-}"
  local force="${5:-false}"

  # Check dependencies
  if ! ubi_check_deps; then
    return 1
  fi

  # Set install directory to $XDG_DATA_HOME/<app_name>
  local install_dir="${XDG_DATA_HOME}/${app_name}"

  # Check if already installed (unless forced)
  if [ "$force" != "true" ] && [ -d "$install_dir" ]; then
    log info "already installed" "skipping installation"
    return 0
  fi

  # Create install directory
  mkdir -p "$install_dir"

  log info "installing" "$app_name from $project"

  # Always use --extract-all to get full release contents
  if ! ubi --project "$project" --in "$install_dir" --extract-all; then
    log error "installation failed" "$app_name"
    return 1
  fi

  # Handle bin symlinks
  # Default: if no bin specified, symlink <app_name> from root to $XDG_BIN_HOME/<app_name>
  if [ -z "$bin" ]; then
    bin="$app_name"
  fi

  ubi_create_bin_symlinks "$app_name" "$install_dir" "$bin"

  # Handle supplementary symlinks (man pages, completions, etc.)
  if [ -n "$symlinks" ]; then
    ubi_create_symlinks "$install_dir" "$symlinks"
  fi

  log info "installed" "$app_name"
  return 0
}

# Create bin symlinks for installed tool
# Args:
#   $1 - App name (for logging)
#   $2 - Install directory
#   $3 - Newline-separated binary definitions (path or path:alias)
ubi_create_bin_symlinks() {
  local app_name="$1"
  local install_dir="$2"
  local bin_defs="$3"

  # Parse binary definitions
  printf '%s\n' "$bin_defs" | while IFS= read -r bin_def; do
    [ -z "$bin_def" ] && continue

    # Parse path:alias format
    local src_path dest_name
    if echo "$bin_def" | grep -q ':'; then
      src_path="${bin_def%%:*}"
      dest_name="${bin_def##*:}"
    else
      src_path="$bin_def"
      dest_name=$(basename "$bin_def")
    fi

    # Make source path absolute
    local src="${install_dir}/${src_path}"

    # Smart binary detection for platform-specific variants
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
        log info "auto-detected" "$(basename "$src") for $dest_name"
      fi
    fi

    # Destination is always in $XDG_BIN_HOME
    local dest="${XDG_BIN_HOME}/${dest_name}"

    # Create destination directory if needed
    mkdir -p "$XDG_BIN_HOME"

    # Remove existing symlink or file
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      rm -f "$dest"
    fi

    # Create symlink
    if [ -e "$src" ]; then
      ln -s "$src" "$dest"
      log info "symlink created" "$dest_name -> $(basename "$src")"
    else
      log warn "binary not found" "$src_path"
    fi
  done
}

# Create supplementary symlinks (man pages, completions, etc.)
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
#   $1 - App name
#   $2 - Bin array (newline-separated binary definitions)
#   $3 - Symlinks (newline-separated "src:dest" pairs)
ubi_uninstall() {
  local app_name="$1"
  local bin="${2:-}"
  local symlinks="${3:-}"

  local install_dir="${XDG_DATA_HOME}/${app_name}"

  log info "uninstalling" "$app_name"

  # Remove bin symlinks
  if [ -z "$bin" ]; then
    bin="$app_name"
  fi

  printf '%s\n' "$bin" | while IFS= read -r bin_def; do
    [ -z "$bin_def" ] && continue

    # Parse path:alias format to get destination name
    local dest_name
    if echo "$bin_def" | grep -q ':'; then
      dest_name="${bin_def##*:}"
    else
      dest_name=$(basename "$bin_def")
    fi

    local dest="${XDG_BIN_HOME}/${dest_name}"
    if [ -L "$dest" ] || [ -e "$dest" ]; then
      rm -f "$dest"
      log info "removed symlink" "$dest_name"
    fi
  done

  # Remove supplementary symlinks
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

  # Remove installation directory
  if [ -d "$install_dir" ]; then
    rm -rf "$install_dir"
    log info "removed directory" "$install_dir"
  fi

  log info "uninstalled" "$app_name"
  return 0
}

# Get status of installed tool
# Args:
#   $1 - App name
#   $2 - Bin array (for determining primary binary)
#   $3 - Status command (optional, defaults to "<primary_bin> --version" or "<primary_bin> version")
ubi_status() {
  local app_name="$1"
  local bin="${2:-}"
  local status_cmd="${3:-}"

  local install_dir="${XDG_DATA_HOME}/${app_name}"

  # Check if installed
  if [ ! -d "$install_dir" ]; then
    log_status "$app_name" "ubi" "not installed" "warn"
    return 0
  fi

  # Determine primary binary (first in bin array)
  local primary_bin
  if [ -z "$bin" ]; then
    primary_bin="$app_name"
  else
    local first_bin
    first_bin=$(printf '%s\n' "$bin" | head -1)
    if echo "$first_bin" | grep -q ':'; then
      primary_bin="${first_bin##*:}"
    else
      primary_bin=$(basename "$first_bin")
    fi
  fi

  # Determine status command
  if [ -z "$status_cmd" ]; then
    # Try default commands
    if command -v "$primary_bin" >/dev/null 2>&1; then
      # Try --version first
      if output=$("$primary_bin" --version 2>&1 | head -1) && [ -n "$output" ]; then
        log_status "$app_name" "ubi" "$output"
        return 0
      # Try version second
      elif output=$("$primary_bin" version 2>&1 | head -1) && [ -n "$output" ]; then
        log_status "$app_name" "ubi" "$output"
        return 0
      else
        log_status "$app_name" "ubi" "installed"
        return 0
      fi
    else
      log_status "$app_name" "ubi" "not in PATH" "error"
      return 1
    fi
  else
    # Use custom status command
    if output=$(eval "$status_cmd" 2>&1 | head -1) && [ -n "$output" ]; then
      log_status "$app_name" "ubi" "$output"
      return 0
    else
      log_status "$app_name" "ubi" "status check failed" "error"
      return 1
    fi
  fi
}

# Update tool (reinstall)
# Args: same as ubi_install (but force=true is added)
ubi_update() {
  log info "updating" "$1"
  # Call install with force=true (5th parameter)
  ubi_install "$1" "$2" "$3" "$4" "true"
}
