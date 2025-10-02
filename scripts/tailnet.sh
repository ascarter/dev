#!/bin/sh

# Initialize tailnet

set -eu

# Source log library for performance
. "$(dirname "$0")/../lib/log.sh"

case $(uname -s) in
Darwin)
  log info "tailscale" "Use Tailscale menu bar item to join tailnet"
  ;;
Linux)
  if command -v tailscaled >/dev/null 2>&1; then
    sudo tailscale up --ssh --accept-routes --operator=$USER --reset
    tailscale ip -4
  else
    log error "Tailscale not installed. Run tailscale setup script first"
    exit 1
  fi
  ;;
esac
