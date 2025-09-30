#!/bin/sh

set -eu

: "${LOCAL_BIN_HOME:=$HOME/.local/bin}"

if ! command -v ubi >/dev/null 2>&1; then
  echo "Install ubi"
  curl --silent --location \
    https://raw.githubusercontent.com/houseabsolute/ubi/master/bootstrap/bootstrap-ubi.sh |
    TARGET=${LOCAL_BIN_HOME} sh
fi
