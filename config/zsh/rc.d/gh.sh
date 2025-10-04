# GitHub CLI shell configuration

if command -v gh >/dev/null 2>&1; then
  _gh_wrapper() {
    eval "$(gh completion -s zsh)"
    _gh "$@"
  }
  compdef _gh_wrapper gh
fi

# Add the GitHub REMOTE MCP server to Claude Code using your gh token
enable_github_mcp() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "Error: claude CLI not found in PATH."
    return 1
  fi
  if ! command -v gh >/dev/null 2>&1; then
    echo "Error: gh CLI not found in PATH."
    return 1
  fi

  # Already configured?
  if claude mcp list 2>/dev/null | grep -Eq '(^github\b|https://api\.githubcopilot\.com/mcp/)' ; then
    echo "GitHub remote MCP server already configured."
    return 0
  fi

  # Ensure gh is authenticated
  if ! gh auth status >/dev/null 2>&1; then
    echo "GitHub CLI is not authenticated. Run 'gh auth login' first."
    return 1
  fi

  # Use the current gh token
  local gh_token
  gh_token=$(gh auth token 2>/dev/null)
  if [[ -z "$gh_token" ]]; then
    echo "Failed to retrieve token from gh CLI."
    return 1
  fi

  echo "Adding GitHub remote MCP server (HTTP) with gh token…"
  claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
    --header "Authorization: Bearer ${gh_token}"

  local exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    echo "GitHub remote MCP server added."
  else
    echo "Failed to add GitHub remote MCP server (exit code $exit_code)."
  fi
}
