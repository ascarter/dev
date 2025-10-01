# GitHub CLI shell configuration

if command -v gh >/dev/null 2>&1; then
  _gh_wrapper() {
    eval "$(gh completion -s zsh)"
    _gh "$@"
  }
  compdef _gh_wrapper gh
fi
