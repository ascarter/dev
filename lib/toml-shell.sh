#!/bin/sh

# toml.sh - Simple TOML parser library
#
# Usage:
#   . "${DEV_HOME}/lib/toml.sh"
#   parse_toml "config.toml" | while IFS="$(printf '\t')" read -r section key value; do
#     echo "[$section] $key = $value"
#   done
#
# Output format: section<TAB>key<TAB>value
# Each line represents a key-value pair within a section
# For arrays: section<TAB>key[0]<TAB>value, section<TAB>key[1]<TAB>value, etc.

# Parse simple TOML (limited parser for our needs)
# Supports:
# - Section headers: [section.name]
# - Key-value pairs: key = "value" or key = value
# - Inline arrays: key = ["value1", "value2", "value3"]
# - Comments: # comment
# - Empty lines
#
# Does not support:
# - Multi-line arrays (arrays must be on a single line)
# - Nested tables
# - Multi-line strings
# - Inline tables (objects)
#
# Note: Arrays must be written on a single line:
#   symlinks = ["a", "b", "c"]  # OK
#   symlinks = [                # NOT SUPPORTED
#     "a",
#     "b"
#   ]
#
parse_toml() {
  local toml_file="$1"
  local current_section=""

  if [ ! -f "$toml_file" ]; then
    printf 'ERROR: TOML file not found: %s\n' "$toml_file" >&2
    return 1
  fi

  # Read and parse the TOML file
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    case "$line" in
    '' | '#'*) continue ;;
    esac

    # Remove inline comments (simple approach - doesn't handle # in strings)
    line=$(printf '%s' "$line" | sed 's/[[:space:]]*#.*$//')

    # Skip if line became empty after removing comment
    [ -z "$line" ] && continue

    # Section headers [section.name]
    if printf '%s' "$line" | grep -q '^\[.*\]$'; then
      current_section=$(printf '%s' "$line" | sed 's/^\[\(.*\)\]$/\1/')
      continue
    fi

    # Key-value pairs
    if printf '%s' "$line" | grep -q '='; then
      # Split on first = sign
      key=$(printf '%s' "$line" | cut -d= -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      value=$(printf '%s' "$line" | cut -d= -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

      # Check if value is an inline array [...]
      if printf '%s' "$value" | grep -q '^\[.*\]$'; then
        # Parse array elements
        # Remove outer brackets and parse comma-separated values
        array_content=$(printf '%s' "$value" | sed 's/^\[//;s/\]$//')

        # Use awk to split by commas, respecting quotes
        printf '%s\n' "$array_content" | awk -v section="$current_section" -v key="$key" '
        {
          idx = 0
          in_quote = 0
          element = ""

          for (i = 1; i <= length($0); i++) {
            c = substr($0, i, 1)

            if (c == "\"" && (i == 1 || substr($0, i-1, 1) != "\\")) {
              in_quote = !in_quote
            } else if (c == "," && !in_quote) {
              # End of element
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", element)
              gsub(/^"+|"+$/, "", element)
              if (element != "") {
                printf "%s\t%s[%d]\t%s\n", section, key, idx, element
                idx++
              }
              element = ""
            } else {
              element = element c
            }
          }

          # Last element
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", element)
          gsub(/^"+|"+$/, "", element)
          if (element != "") {
            printf "%s\t%s[%d]\t%s\n", section, key, idx, element
          }
        }'
      else
        # Regular value - remove quotes if present
        value=$(printf '%s' "$value" | sed 's/^"//;s/"$//')

        # Output: section<TAB>key<TAB>value
        if [ -n "$current_section" ]; then
          printf '%s\t%s\t%s\n' "$current_section" "$key" "$value"
        fi
      fi
    fi
  done <"$toml_file"
}

# Parse TOML and extract all sections
# Returns a list of unique section names
toml_sections() {
  local toml_file="$1"
  parse_toml "$toml_file" | cut -f1 | sort -u
}

# Get all keys for a specific section
toml_section_keys() {
  local toml_file="$1"
  local section="$2"
  parse_toml "$toml_file" | awk -F'\t' -v sec="$section" '$1 == sec {print $2}' | sed 's/\[[0-9]*\]$//' | sort -u
}

# Get value for a specific section and key
# For arrays, returns all array elements separated by newlines
# For regular values, returns single value
toml_get() {
  local toml_file="$1"
  local section="$2"
  local key="$3"

  # Check if it's an array by looking for key[0]
  if parse_toml "$toml_file" | grep -q "^${section}	${key}\[0\]"; then
    # Return all array elements
    parse_toml "$toml_file" | awk -F'\t' -v sec="$section" -v k="$key" \
      '$1 == sec && $2 ~ "^" k "\\[[0-9]+\\]$" {print $3}'
  else
    # Return single value
    parse_toml "$toml_file" | awk -F'\t' -v sec="$section" -v k="$key" \
      '$1 == sec && $2 == k {print $3; exit}'
  fi
}

# Get array length for a specific section and key
# Returns 0 if not an array or empty
toml_array_length() {
  local toml_file="$1"
  local section="$2"
  local key="$3"
  parse_toml "$toml_file" | awk -F'\t' -v sec="$section" -v k="$key" \
    '$1 == sec && $2 ~ "^" k "\\[[0-9]+\\]$"' | wc -l | tr -d ' '
}
