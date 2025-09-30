#!/bin/sh

# Yubikey install script

set -eu

YUBICO_AUTHENTICATOR_ROOT="$XDG_DATA_HOME/yubico-authenticator"
YUBICO_AUTHENTICATOR_DESKTOP_SCRIPT="$YUBICO_AUTHENTICATOR_ROOT/desktop_integration.sh"

case $(uname -s) in
Linux)
  YUBICO_AUTHENTICATOR_URL="https://developers.yubico.com/yubioath-flutter/Releases/yubico-authenticator-latest-linux.tar.gz"
  curl -sSL "$YUBICO_AUTHENTICATOR_URL" | tar -xz -C "$YUBICO_AUTHENTICATOR_ROOT" --strip-components=1

  # Enable desktop integration
  if [ -f "$YUBICO_AUTHENTICATOR_DESKTOP_SCRIPT" ]; then
    "$YUBICO_AUTHENTICATOR_DESKTOP_SCRIPT" --install
  fi
  ;;
esac

