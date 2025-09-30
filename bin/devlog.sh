# devlog.sh - Sourceable logging library for dev scripts
#
# Source this file to get log functions without process overhead
#
# Usage after sourcing:
#   log info <label> [message]    - Info message (default)
#   log warn <label> [message]    - Warning message (yellow label)
#   log error <label> [message]   - Error message (red label, stderr)
#   log debug <label> [message]   - Log only if VERBOSE=1
#   log <label>                   - Simple message (info level)
#
# Environment Variables:
#   DEVLOG_WIDTH - Field width for label column (default: 16)
#   VERBOSE      - Enable verbose logging (0 or 1)
#
# Examples:
#   . "$(dirname "$0")/../bin/devlog.sh"
#   log info "install" "Installing package"
#   log warn "deprecated" "This feature is deprecated"
#   log error "failed" "Installation failed"
#   log debug "trace" "Debug information"

# Prevent multiple sourcing
if [ -n "${DEVLOG_SOURCED:-}" ]; then
  return 0
fi
DEVLOG_SOURCED=1

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

# Main log function
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
