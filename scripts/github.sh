#!/bin/sh

set -eu

# GitHub CLI extensions installer
if command -v gh >/dev/null 2>&1; then
  if ! gh auth status; then
    if ! gh auth login --git-protocol https --hostname github.com --web; then
      echo "Failed to authenticate with GitHub"
      exit 1
    fi
  fi

  for extension in github/gh-copilot; do
    gh extension install ${extension} || true
  done
fi
