#!/bin/sh

set -eu

if ! command -v claude >/dev/null 2>&1; then
  echo "Install Claude Code native app"
  curl -fsSL claude.ai/install.sh | bash
fi
