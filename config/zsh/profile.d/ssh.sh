# Set SSH key provider for FIDO2
if [ -f /usr/local/lib/sk-libfido2.dylib ]; then
  export SSH_SK_PROVIDER=/usr/local/lib/sk-libfido2.dylib
fi

if command -v ssh-askpass >/dev/null; then
  export SSH_ASKPASS=ssh-askpass
  export DISPLAY=:0
fi

if [ -n "${SSH_CONNECTION}" ]; then
  export PINENTRY_USER_DATA=USE_CURSES=1
  export GPG_TTY=$(tty)
fi
