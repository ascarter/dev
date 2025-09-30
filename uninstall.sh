#!/bin/sh

# Uninstall dev

set -eu

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
DEV_HOME=${DEV_HOME:-${XDG_DATA_HOME}/dev}
DEV_CONFIG=${DEV_CONFIG:-${XDG_CONFIG_HOME}/dev}
TARGET=${TARGET:-$HOME}

# Use devlog for consistent logging
log() {
  if [ -x "${DEV_HOME}/bin/devlog" ]; then
    "${DEV_HOME}/bin/devlog" "$@"
  else
    # Fallback to echo if devlog not available
    shift # Remove level
    echo "$@"
  fi
}

usage() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -d  Dev directory (default: ${DEV_HOME})"
  echo "  -t  Target directory to remove symlinks (default: ${TARGET})"
  echo "  -v  Verbose output"
  echo "  -h  Show usage"
}

FLAGS=

while getopts ":vhd:t:" opt; do
  case ${opt} in
  d) DEV_HOME=${OPTARG} ;;
  t) TARGET=${OPTARG} ;;
  v) FLAGS="-v" ;;
  h) usage && exit 0 ;;
  \?) usage && exit 1 ;;
  esac
done
shift $((OPTIND - 1))

remove_path() {
  path="$1"
  if [ -e "$path" ]; then
    printf "Are you sure you want to remove '%s'? [y/N] " "$path"
    read answer
    case "$answer" in
    [Yy]*)
      log info "uninstall" "Remove $path"
      rm -rf "$path"
      ;;
    *)
      log info "uninstall" "Skip $path"
      ;;
    esac
  else
    log info "uninstall" "Missing $path"
  fi
}

# Remove dev configuration
${DEV_HOME}/bin/dev ${FLAGS} -d ${DEV_HOME} -t ${TARGET} config unlink

# Remove bootstrap from .zshenv
ZSHENV="${TARGET}/.zshenv"
if [ -f "$ZSHENV" ]; then
  log info "uninstall" "Remove dev bootstrap from $ZSHENV"
  sed -i.bak '/# dev - Development environment management/d' "$ZSHENV"
  sed -i.bak '/eval.*dev env/d' "$ZSHENV"
  rm -f "${ZSHENV}.bak"
fi

remove_path "${DEV_CONFIG}"
remove_path "${DEV_HOME}"

log ""
log info "uninstall" "dev uninstalled"
log info "uninstall" "Reload session to apply configuration"
