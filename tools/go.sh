#!/bin/sh

# Go toolchain management

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_BIN_HOME=${XDG_BIN_HOME:-${XDG_DATA_HOME}/../bin}
GOROOT="${GOROOT:-${XDG_DATA_HOME}/go}"

# Use devlog for consistent logging
log() {
  "$(dirname "$0")/../bin/devlog" log "$@"
}

install() {
  # Detect OS and architecture
  local os arch
  case "$(uname -s)" in
  Linux*) os="linux" ;;
  Darwin*) os="darwin" ;;
  *)
    log "go" "unsupported OS: $(uname -s)"
    return 1
    ;;
  esac

  case "$(uname -m)" in
  x86_64) arch="amd64" ;;
  aarch64 | arm64) arch="arm64" ;;
  *)
    log "go" "unsupported architecture: $(uname -m)"
    return 1
    ;;
  esac

  # Check dependencies
  if ! command -v curl >/dev/null 2>&1; then
    log "go" "curl is required for installation"
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    log "go" "jq is required for installation"
    return 1
  fi

  # Determine checksum command (prefer shasum on macOS)
  local SHASUM_CMD
  if command -v shasum >/dev/null 2>&1; then
    SHASUM_CMD="shasum -a 256 -c"
  elif command -v sha256sum >/dev/null 2>&1 && sha256sum -c </dev/null >/dev/null 2>&1; then
    SHASUM_CMD="sha256sum -c"
  else
    log "go" "shasum or GNU sha256sum is required for installation"
    return 1
  fi

  local ext="tar.gz"
  local GO_RELEASES_URL="https://go.dev/dl/?mode=json"
  local jq_filter='
    .[0].files[]
    | select(
      .os == $os and .arch == $arch and (
        .filename | endswith($ext)
      )
    )
    | [.filename, .sha256, .version]
    | @tsv'

  # Get release details
  local filename checksum version
  read filename checksum version <<EOF
$(curl -s "$GO_RELEASES_URL" | jq -r --arg os "$os" --arg arch "$arch" --arg ext "$ext" "$jq_filter")
EOF

  # Verify version found
  if [ -z "$version" ] || [ -z "$filename" ] || [ -z "$checksum" ]; then
    log "go" "no matching stable release found for '$arch-$os'"
    return 1
  fi

  # Check if existing Go install matches current stable
  if [ -d "${GOROOT}" ] && [ -x "${GOROOT}/bin/go" ]; then
    local current_version_output
    current_version_output=$("${GOROOT}/bin/go" version 2>/dev/null || echo "")
    if [ "$current_version_output" = "go version $version $os/$arch" ]; then
      log "go" "already installed latest version $version"
      return 0
    fi
  fi

  log "go" "installing Go $version to ${GOROOT}"

  # Download to temporary file
  local tmpfile
  tmpfile=$(mktemp)
  trap 'rm -f "$tmpfile"' EXIT

  log "go" "downloading $filename"
  if ! curl -fsSL -o "$tmpfile" "https://go.dev/dl/$filename"; then
    log "go" "failed to download Go"
    return 1
  fi

  # Verify checksum
  log "go" "verifying checksum"
  echo "$checksum  $tmpfile" | $SHASUM_CMD >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    log "go" "checksum verification failed"
    return 1
  fi

  # Remove existing installation
  if [ -d "${GOROOT}" ]; then
    rm -rf "${GOROOT}"
  fi

  # Extract Go
  log "go" "extracting to ${GOROOT}"
  mkdir -p "${GOROOT}"
  if ! tar -xzf "$tmpfile" -C "${GOROOT}" --strip-components=1; then
    log "go" "failed to extract Go"
    rm -rf "${GOROOT}"
    return 1
  fi

  log "go" "installation complete"
}

update() {
  if ! [ -d "${GOROOT}" ]; then
    log "go" "not installed"
    return 1
  fi

  log "go" "updating Go installation"
  # For Go, update is essentially reinstall
  install
}

uninstall() {
  if [ -d "${GOROOT}" ]; then
    log "go" "removing Go installation"
    rm -rf "${GOROOT}"
  else
    log "go" "already uninstalled"
  fi
}

status() {
  if [ -d "${GOROOT}" ] && [ -x "${GOROOT}/bin/go" ]; then
    local current_version
    current_version=$("${GOROOT}/bin/go" version 2>/dev/null | cut -d' ' -f3 || echo "unknown")
    log "go" "installed, version: ${current_version}"
  else
    log "go" "not installed"
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
