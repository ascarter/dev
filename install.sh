#!/bin/sh

# Install dev

set -eu

# Define XDG directories if not already set
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}

# Default directories and settings
DEV_HOME=${DEV_HOME:-${XDG_DATA_HOME}/dev}
DEV_BRANCH=${DEV_BRANCH:-main}
TARGET=${TARGET:-$HOME}

usage() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -b  Branch (default: ${DEV_BRANCH})"
  echo "  -d  Directory to install dev (default: ${DEV_HOME})"
  echo "  -t  Target directory to create symlinks (default: ${TARGET})"
  echo "  -v  Verbose output"
  echo "  -h  Show usage"
}

prompt() {
  choice="N"
  read -p "$1 (y/N) " -n 1 choice
  echo
  case $choice in
  [yY]) return 0 ;;
  *) return 1 ;;
  esac
}

get_platform_id() {
  case "$(uname -s)" in
  Darwin)
    echo "macos"
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      # Source the os-release file to get ID and VARIANT_ID
      . /etc/os-release
      echo "${ID}"
    else
      echo "linux-unknown"
    fi
    ;;
  *)
    echo "unknown"
    ;;
  esac
}

FLAGS=""

while getopts ":vhb:d:t:" opt; do
  case ${opt} in
  b) DEV_BRANCH=${OPTARG} ;;
  d) DEV_HOME=${OPTARG} ;;
  t) TARGET=${OPTARG} ;;
  v) FLAGS="-v" ;;
  h) usage && exit 0 ;;
  \?) usage && exit 1 ;;
  esac
done
shift $((OPTIND - 1))

PLATFORM_ID=$(get_platform_id)

# Check if git is installed
if ! command -v git >/dev/null 2>&1; then
  case "$PLATFORM_ID" in
  macos)
    if prompt "Install Xcode command line tools?"; then
      xcode-select --install
    else
      echo "Please install Xcode command line tools: xcode-select --install" >&2
      exit 1
    fi
    ;;
  fedora)
    if prompt "Install git using dnf?"; then
      sudo dnf install -y git
    else
      echo "Please install git using your package manager: sudo dnf install git" >&2
      exit 1
    fi
    ;;
  ubuntu | debian)
    if prompt "Install git using apt?"; then
      sudo apt install -y git
    else
      echo "Please install git using your package manager: sudo apt install git" >&2
      exit 1
    fi
    ;;
  *)
    echo "Git is not installed. Please install git and try again." >&2
    exit 1
    ;;
  esac
fi

# Clone dev
if [ ! -d "${DEV_HOME}" ]; then
  echo "Clone dev ($DEV_BRANCH) -> ${DEV_HOME}"
  mkdir -p $(dirname "${DEV_HOME}")
  git clone -b ${DEV_BRANCH} https://github.com/ascarter/dev.git ${DEV_HOME}
else
  echo "dev directory already exists at ${DEV_HOME}"
  if prompt "Update existing dev?"; then
    echo "Updating dev..."
    git -C "${DEV_HOME}" pull
  fi
fi

# Init dev
"${DEV_HOME}/bin/dev" ${FLAGS} -d "${DEV_HOME}" -t "${TARGET}" init

# Link config files
"${DEV_HOME}/bin/dev" ${FLAGS} -d "${DEV_HOME}" -t "${TARGET}" config link

# Run appropriate host provisioning script
HOST_SCRIPT="${DEV_HOME}/hosts/${PLATFORM_ID}.sh"
if [ -f "${HOST_SCRIPT}" ]; then
  if prompt "Run ${HOST_ID} host provisioning script?"; then
    "${HOST_SCRIPT}"
  fi
else
  echo "No host provisioning script found for ${PLATFORM_ID}"
fi

echo ""
echo "dev installation complete"
echo "Reload your session to apply configuration"
