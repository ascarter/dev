#!/bin/sh

set -eu

# Source log library for performance
. "$(dirname "$0")/../lib/log.sh"

# GitHub CLI extensions installer
if command -v gh >/dev/null 2>&1; then
  if ! gh auth status; then
    if ! gh auth login --git-protocol https --hostname github.com --web; then
      log error "Failed to authenticate with GitHub"
      exit 1
    fi
  fi

  for extension in github/gh-copilot; do
    gh extension install ${extension} || true
  done
fi
