# Tailscale shell configuration

if [ -n "$PS1" ] && command -v tailscale >/dev/null 2>&1; then
  eval "$(tailscale completion zsh)"
fi
