#!/bin/sh

# curl.sh - Curl-based installer backend for app management
#
# This library provides functions for installing applications via curl-piped
# install scripts. It is designed to be sourced by the main app.sh module.
#
# Functions:
#   curl_install <url> <shell> <env_vars> <args> <check_cmd> <update_cmd>
#   curl_uninstall <app_name> <check_cmd> <uninstall_method>
#   curl_status <app_name> <check_cmd>
#
# Notes:
#   - url: URL to the install script
#   - shell: Shell to pipe to (bash, sh, zsh)
#   - env_vars: Newline-separated "KEY=value" pairs
#   - args: Arguments to pass to installer (via -s --)
#   - check_cmd: Command to verify installation (e.g., "claude --version")
#   - update_cmd: Command for self-update (optional, empty if none)
#   - uninstall_method: "self" (has self-uninstall), "manual" (remove binary), or "none"
#
# Dependencies:
#   - curl
#   - log library (for logging)

# Check if curl is available
curl_check_deps() {
  if ! command -v curl >/dev/null 2>&1; then
    log error "curl not found" "curl is required for this installer"
    return 1
  fi
  return 0
}

# Install tool using curl-piped installer
# Args:
#   $1 - App name
#   $2 - URL to install script
#   $3 - Shell to use (bash, sh, zsh)
#   $4 - Environment variables (newline-separated "KEY=value" pairs)
#   $5 - Arguments to pass to installer
#   $6 - Check command to verify installation (optional, defaults to <app_name> --version)
#   $7 - Update command (optional)
curl_install() {
  local app_name="$1"
  local url="$2"
  local shell="${3:-sh}"
  local env_vars="${4:-}"
  local args="${5:-}"
  local check_cmd="${6:-}"
  local update_cmd="${7:-}"

  # Check dependencies
  if ! curl_check_deps; then
    return 1
  fi

  # Check if already installed (idempotency)
  local bin_name="$app_name"
  if [ -n "$check_cmd" ]; then
    bin_name=$(echo "$check_cmd" | awk '{print $1}')
  fi

  if command -v "$bin_name" >/dev/null 2>&1; then
    log info "already installed" "skipping installation"
    return 0
  fi

  log info "installing" "via curl installer from $url"

  # Build the install command
  local install_cmd="curl -fsSL \"$url\""

  # Add environment variables if specified
  if [ -n "$env_vars" ]; then
    local env_prefix=""
    printf '%s\n' "$env_vars" | while IFS= read -r env_var; do
      [ -z "$env_var" ] && continue
      env_prefix="${env_prefix} ${env_var}"
    done
    install_cmd="${env_prefix} ${install_cmd}"
  fi

  # Pipe to shell with args
  if [ -n "$args" ]; then
    install_cmd="${install_cmd} | ${shell} -s -- ${args}"
  else
    install_cmd="${install_cmd} | ${shell}"
  fi

  # Execute installation
  if ! eval "$install_cmd"; then
    log error "installation failed" "curl installer returned error"
    return 1
  fi

  log info "installed" "installation complete"
  return 0
}

# Update tool
# Args:
#   $1 - App name
#   $2 - Check command
#   $3 - Update command (optional, empty means reinstall)
#   $4 - Install URL (for reinstall if no update command)
#   $5 - Shell (for reinstall)
#   $6 - Env vars (for reinstall)
#   $7 - Args (for reinstall)
curl_update() {
  local app_name="$1"
  local check_cmd="$2"
  local update_cmd="${3:-}"
  local url="${4:-}"
  local shell="${5:-sh}"
  local env_vars="${6:-}"
  local args="${7:-}"

  # Check if installed
  local bin_name="$app_name"
  if [ -n "$check_cmd" ]; then
    bin_name=$(echo "$check_cmd" | awk '{print $1}')
  fi

  if ! command -v "$bin_name" >/dev/null 2>&1; then
    log error "not installed" "$app_name is not installed"
    return 1
  fi

  # If has self-update command, use it
  if [ -n "$update_cmd" ]; then
    log info "updating" "via $update_cmd"
    if ! eval "$update_cmd"; then
      log error "update failed" "$update_cmd returned error"
      return 1
    fi
    log info "updated" "update complete"
    return 0
  fi

  # Otherwise, reinstall
  log info "updating" "reinstalling from $url"
  curl_install "$app_name" "$url" "$shell" "$env_vars" "$args" "$check_cmd" "$update_cmd"
}

# Uninstall tool
# Args:
#   $1 - App name
#   $2 - Uninstall command (optional, defaults to removing binary)
#   $3 - Check command (for default uninstall)
curl_uninstall() {
  local app_name="$1"
  local uninstall_cmd="${2:-}"
  local check_cmd="${3:-}"

  log info "uninstalling" "$app_name"

  # If uninstall command provided, use it
  if [ -n "$uninstall_cmd" ]; then
    log info "running" "$uninstall_cmd"
    if ! eval "$uninstall_cmd"; then
      log error "uninstall failed" "$uninstall_cmd returned error"
      return 1
    fi
    log info "uninstalled" "uninstall complete"
    return 0
  fi

  # Default: remove binary
  local bin_name="$app_name"
  if [ -n "$check_cmd" ]; then
    bin_name=$(echo "$check_cmd" | awk '{print $1}')
  fi

  if command -v "$bin_name" >/dev/null 2>&1; then
    local bin_path
    bin_path=$(command -v "$bin_name")
    log info "removing binary" "$bin_path"
    rm -f "$bin_path"
    log info "uninstalled" "uninstall complete"
    return 0
  else
    log warn "binary not found" "$bin_name not in PATH"
    return 1
  fi
}

# Get status of installed tool
# Args:
#   $1 - App name
#   $2 - Check command (optional, defaults to "<app_name> --version" or "<app_name> version")
curl_status() {
  local app_name="$1"
  local check_cmd="${2:-}"

  # Default: use app_name as binary name
  local bin_name="$app_name"

  # If check_cmd provided, extract binary name from it
  if [ -n "$check_cmd" ]; then
    bin_name=$(echo "$check_cmd" | awk '{print $1}')
  fi

  # Check if binary exists
  if ! command -v "$bin_name" >/dev/null 2>&1; then
    log_status "$app_name" "curl" "not installed" "warn"
    return 0
  fi

  # Try to get version info
  local output

  if [ -n "$check_cmd" ]; then
    # Use provided check command
    if output=$(eval "$check_cmd" 2>&1 | head -1) && [ -n "$output" ]; then
      log_status "$app_name" "curl" "$output"
      return 0
    fi
  else
    # Try default version commands
    if output=$("$bin_name" --version 2>&1 | head -1) && [ -n "$output" ]; then
      log_status "$app_name" "curl" "$output"
      return 0
    elif output=$("$bin_name" version 2>&1 | head -1) && [ -n "$output" ]; then
      log_status "$app_name" "curl" "$output"
      return 0
    fi
  fi

  # Binary exists but version check failed
  log_status "$app_name" "curl" "installed"
  return 0
}
