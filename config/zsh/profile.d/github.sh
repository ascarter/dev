# GitHub CLI configuration

# Only load aliases in interactive shell
if [ -n "$PS1" ] && command -v gh >/dev/null 2>&1; then
  # Generate GitHub Copilot aliases
  if gh extension list | grep -q copilot; then
    eval "$(gh copilot alias -- zsh)"
  fi
fi
