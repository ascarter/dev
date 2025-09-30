export GOPATH="${XDG_STATE_HOME}/go"
export GOROOT="${GOROOT:-${XDG_DATA_HOME}/go}"
export GOMODCACHE="${XDG_CACHE_HOME}/go/mod"

# Add Go binaries to PATH
if [ -d "${GOROOT}/bin" ]; then
  export PATH="${GOROOT}/bin:$PATH"
fi

if command -v go >/dev/null 2>&1; then
  export PATH=$(go env GOPATH)/bin:$PATH
fi
