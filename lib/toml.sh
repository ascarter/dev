#!/bin/sh

# toml-yq.sh - TOML parser library using yq
#
# This is a drop-in replacement for toml.sh that uses yq for parsing.
# yq provides robust TOML parsing with full spec support.
#
# Usage:
#   . "${DEV_HOME}/lib/toml-yq.sh"
#   toml_get "config.toml" "section" "key"
#   toml_sections "config.toml"
#
# Dependencies:
#   - yq (https://github.com/mikefarah/yq/)
#
# Note: This parser uses yq to convert TOML to JSON, then queries the JSON.
# Arrays are returned as newline-separated values for easy shell iteration.

# Check if yq is available
_toml_check_yq() {
  if ! command -v yq >/dev/null 2>&1; then
    printf 'ERROR: yq is not installed. Install it first: dev app install yq\n' >&2
    return 1
  fi
  return 0
}

# Convert TOML file to JSON for internal processing
# Args:
#   $1 - TOML file path
# Returns: JSON string
_toml_to_json() {
  local toml_file="$1"

  if [ ! -f "$toml_file" ]; then
    printf 'ERROR: TOML file not found: %s\n' "$toml_file" >&2
    return 1
  fi

  if ! _toml_check_yq; then
    return 1
  fi

  yq -p toml -o json '.' "$toml_file" 2>/dev/null
}

# Get all top-level sections (keys) from TOML file
# Args:
#   $1 - TOML file path
# Returns: List of section names, one per line
toml_sections() {
  local toml_file="$1"

  if ! _toml_check_yq; then
    return 1
  fi

  yq -p toml -o json 'keys | .[]' "$toml_file" 2>/dev/null | sed 's/^"//;s/"$//'
}

# Get all keys for a specific section
# Args:
#   $1 - TOML file path
#   $2 - Section name
# Returns: List of key names, one per line
toml_section_keys() {
  local toml_file="$1"
  local section="$2"

  if ! _toml_check_yq; then
    return 1
  fi

  yq -p toml -o json ".[\"$section\"] | keys | .[]" "$toml_file" 2>/dev/null | sed 's/^"//;s/"$//'
}

# Get value for a specific section and key
# Args:
#   $1 - TOML file path
#   $2 - Section name
#   $3 - Key name
# Returns: Value (for arrays, returns elements separated by newlines)
toml_get() {
  local toml_file="$1"
  local section="$2"
  local key="$3"

  if ! _toml_check_yq; then
    return 1
  fi

  # Query the value
  local result
  result=$(yq -p toml -o json ".[\"$section\"][\"$key\"]" "$toml_file" 2>/dev/null)

  # Check if result is null (key doesn't exist)
  if [ "$result" = "null" ] || [ -z "$result" ]; then
    return 0
  fi

  # Check if result is an array (starts with [)
  if printf '%s' "$result" | grep -q '^\['; then
    # Parse JSON array and output elements, one per line, removing quotes
    printf '%s\n' "$result" | yq -p json -o json '.[]' 2>/dev/null | sed 's/^"//;s/"$//'
  else
    # Regular value - remove quotes if it's a string
    printf '%s\n' "$result" | sed 's/^"//;s/"$//'
  fi
}

# Get array length for a specific section and key
# Args:
#   $1 - TOML file path
#   $2 - Section name
#   $3 - Key name
# Returns: Number of elements (0 if not an array or empty)
toml_array_length() {
  local toml_file="$1"
  local section="$2"
  local key="$3"

  if ! _toml_check_yq; then
    return 1
  fi

  local result
  result=$(yq -p toml -o json ".[\"$section\"][\"$key\"] | length" "$toml_file" 2>/dev/null)

  # If not an array or null, return 0
  if [ "$result" = "null" ] || [ -z "$result" ]; then
    printf '0\n'
  else
    printf '%s\n' "$result"
  fi
}

# Get a specific array element by index
# Args:
#   $1 - TOML file path
#   $2 - Section name
#   $3 - Key name
#   $4 - Index (0-based)
# Returns: Array element value
toml_array_get() {
  local toml_file="$1"
  local section="$2"
  local key="$3"
  local index="$4"

  if ! _toml_check_yq; then
    return 1
  fi

  local result
  result=$(yq -p toml -o json ".[\"$section\"][\"$key\"][$index]" "$toml_file" 2>/dev/null)

  if [ "$result" = "null" ] || [ -z "$result" ]; then
    return 0
  fi

  # Remove quotes if it's a string
  printf '%s\n' "$result" | sed 's/^"//;s/"$//'
}

# Legacy function for compatibility with old shell parser
# Parses TOML and outputs in tab-separated format
# Output format: section<TAB>key<TAB>value
# For arrays: section<TAB>key[0]<TAB>value, section<TAB>key[1]<TAB>value, etc.
parse_toml() {
  local toml_file="$1"

  if ! _toml_check_yq; then
    return 1
  fi

  # Get all sections
  toml_sections "$toml_file" | while IFS= read -r section; do
    # Get all keys in section
    toml_section_keys "$toml_file" "$section" | while IFS= read -r key; do
      # Get value
      local value
      value=$(toml_get "$toml_file" "$section" "$key")

      # Check if it's an array by counting lines
      local line_count
      line_count=$(printf '%s' "$value" | grep -c '^' || true)

      if [ "$line_count" -gt 1 ]; then
        # Array - output with indices
        local idx=0
        printf '%s\n' "$value" | while IFS= read -r element; do
          printf '%s\t%s[%d]\t%s\n' "$section" "$key" "$idx" "$element"
          idx=$((idx + 1))
        done
      else
        # Single value
        printf '%s\t%s\t%s\n' "$section" "$key" "$value"
      fi
    done
  done
}
