#!/bin/sh

# Rust toolchain management via rustup

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
RUSTUP_HOME="${RUSTUP_HOME:-${XDG_DATA_HOME}/rustup}"
CARGO_HOME="${CARGO_HOME:-${XDG_DATA_HOME}/cargo}"

# Source devlog library for performance
. "$(dirname "$0")/../bin/devlog.sh"

install() {
  # Check if rustup is already installed
  if command -v rustup >/dev/null 2>&1; then
    log info "rust" "already installed, skipping"
    status
    return 0
  fi

  log info "rust" "installing rustup to ${RUSTUP_HOME}"

  # Install rustup via the official script
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile default --default-toolchain stable --component rust-analyzer --component rust-src
}

update() {
  if ! command -v rustup >/dev/null 2>&1; then
    log info "rust" "not installed"
    return 1
  fi

  log info "rust" "updating rustup and toolchains"
  rustup update
}

uninstall() {
  if command -v rustup >/dev/null 2>&1; then
    rustup self uninstall
  else
    log info "rust" "already uninstalled"
  fi
}

status() {
  if command -v rustup >/dev/null 2>&1; then
    local current_version
    current_version=$(rustup show active-toolchain 2>/dev/null | cut -d' ' -f1 || echo "none")
    log info "rust" "rustup installed, current: ${current_version}"
  else
    log info "rust" "not installed"
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
