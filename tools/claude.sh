#!/bin/sh

# Claude Code CLI management
#
# Note: Claude Code CLI hardcodes ~/.claude for data storage and does not
# support XDG Base Directory specification. The binary is installed to
# ~/.local/bin but all application data goes to ~/.claude

CLAUDE_DIR="${HOME}/.claude" # Hardcoded by Claude, not XDG compliant

# Source log library for performance
. "$(dirname "$0")/../lib/log.sh"

install() {
  # Check if claude is already installed
  if command -v claude >/dev/null 2>&1; then
    log info "claude" "already installed, skipping"
    status
    return 0
  fi

  log info "claude" "installing Claude Code CLI"

  # Install via official script
  if ! curl -fsSL claude.ai/install.sh | bash; then
    log error "claude" "installation failed"
    return 1
  fi

  log info "claude" "installation complete"
}

update() {
  if ! command -v claude >/dev/null 2>&1; then
    log info "claude" "not installed"
    return 1
  fi

  log info "claude" "checking for updates"

  # Use claude's built-in self-update
  if ! claude update; then
    log error "claude" "update failed"
    return 1
  fi

  log info "claude" "update complete"
}

uninstall() {
  if ! command -v claude >/dev/null 2>&1 && [ ! -d "${CLAUDE_DIR}" ]; then
    log info "claude" "already uninstalled"
    return 0
  fi

  log info "claude" "removing Claude Code CLI"

  # Remove the claude binary
  if command -v claude >/dev/null 2>&1; then
    local claude_path
    claude_path=$(command -v claude)
    if [ -f "${claude_path}" ]; then
      rm -f "${claude_path}"
      log info "claude" "removed binary: ${claude_path}"
    fi
  fi

  # Remove claude directory
  if [ -d "${CLAUDE_DIR}" ]; then
    log warn "claude" "removing ${CLAUDE_DIR} (contains history and settings)"
    rm -rf "${CLAUDE_DIR}"
  fi

  log info "claude" "uninstall complete"
}

status() {
  if command -v claude >/dev/null 2>&1; then
    local version
    version=$(claude --version 2>&1 | head -1 || echo "unknown")
    log info "claude" "${version}"
  else
    log info "claude" "not installed"
  fi
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
