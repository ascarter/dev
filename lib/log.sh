#!/bin/sh

# log.sh - Standard logging library for dev scripts
#
# Usage:
#   . "${DEV_HOME}/lib/log.sh"
#   log info "install" "Installing package"
#   log warn "deprecated" "This feature is deprecated"
#   log error "failed" "Installation failed"
#   log debug "trace" "Debug information"
#   log "simple" "Just a message"
#   log  # Print blank line
#
# Environment Variables:
#   DEVLOG_WIDTH - Field width for label column (default: 16)
#   VERBOSE      - Enable verbose logging (0 or 1)

# Prevent multiple sourcing
if [ -n "${LOG_SOURCED:-}" ]; then
  return 0
fi
LOG_SOURCED=1

# Default field width for label column (can be overridden with DEVLOG_WIDTH)
DEVLOG_FIELD_WIDTH=${DEVLOG_WIDTH:-16}

# Internal formatting function
_devlog_format() {
  label="${1:-}"
  message="${2:-}"
  color="${3:-}"

  # Treat empty string as "no message" (same as missing argument)
  if [ -z "$message" ] || [ "$#" -lt 2 ]; then
    # Single argument or empty message - just print it
    if [ -n "$color" ]; then
      printf "${color}%s$(tput sgr0)\n" "$label"
    else
      printf "%s\n" "$label"
    fi
  else
    # Two arguments - format with label and message
    if [ -n "$color" ]; then
      printf "${color}$(tput bold)%-${DEVLOG_FIELD_WIDTH}s$(tput sgr0) %s\n" "$label" "$message"
    else
      printf "$(tput bold)%-${DEVLOG_FIELD_WIDTH}s$(tput sgr0) %s\n" "$label" "$message"
    fi
  fi
}

# Status output function (3 columns: name, type, status)
log_status() {
  local name="$1"
  local type="$2"
  local status="$3"
  local level="${4:-info}"

  case "$level" in
  warn)
    printf "$(tput setaf 3)%-20s %-10s %s$(tput sgr0)\n" "$name" "$type" "$status"
    ;;
  error)
    printf "$(tput setaf 1)%-20s %-10s %s$(tput sgr0)\n" "$name" "$type" "$status" >&2
    ;;
  *)
    printf "%-20s %-10s %s\n" "$name" "$type" "$status"
    ;;
  esac
}

# Main log function (exported for library use)
log() {
  # Handle empty arguments
  if [ "$#" -eq 0 ]; then
    printf "\n"
    return 0
  fi

  # Check if first argument is a known level
  case "$1" in
  info | warn | error | debug)
    level="$1"
    shift
    label="${1:-}"
    message="${2:-}"
    ;;
  *)
    # First arg is not a level, treat as label with default level (info)
    level="info"
    label="$1"
    message="${2:-}"
    ;;
  esac

  # Execute based on level
  case "$level" in
  info)
    _devlog_format "$label" "$message"
    ;;
  warn)
    # Yellow text for warnings
    _devlog_format "$label" "$message" "$(tput setaf 3)"
    ;;
  error)
    # Red text for errors, output to stderr
    _devlog_format "$label" "$message" "$(tput setaf 1)" >&2
    ;;
  debug)
    # Only log if VERBOSE is set
    if [ "${VERBOSE:-0}" -eq 1 ]; then
      _devlog_format "$label" "$message"
    fi
    ;;
  esac
}

# Library is ready - log function is available
