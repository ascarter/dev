#!/bin/sh

# Initialize tailnet

set -eu

case $(uname -s) in
Darwin)
  echo "Use Tailscale menu bar item to join tailnet"
  ;;
Linux)
  if command -v tailscaled >/dev/null 2>&1; then
    sudo tailscale up --ssh --accept-routes --operator=$USER --reset
    tailscale ip -4
  else
    echo "Tailscale not installed. Run tailscale setup script first"
    exit 1
  fi
  ;;
esac

