# Development Notes

## Implementation Plan: dotfiles  dev

### Overview
Transform the existing `dotfiles` repository into the new `dev` system as described in ASSISTANT.md.

**Key Changes:**
- Rename/rebrand from `dotfiles` to `dev`
- Reorganize to match new architecture (separate `hosts/` and `tools/`)
- Avoid Homebrew dependency where possible (make it optional)
- Keep proven symlink management and shell integration patterns

### Phase 1: Core Structure

**1.1 Rename main tool: `bin/dotfiles`  `bin/dev`**
- Update all references to use `dev` command
- Update environment variables (`DOTFILES`  `DEV_HOME`)
- Update command name in help text and logging
- Keep backward compatibility during transition

**1.2 Reorganize directories:**
- Keep: `bin/`, `docs/`
- Rename: `src/`  `config/`
- Split `scripts/` into:
  - `hosts/` - Platform provisioning (macos.sh, fedora.sh, ubuntu.sh)
  - `tools/` - Tool installation scripts (homebrew.sh, github.sh, tailscale.sh, etc.)
- Merge: `toolchains/`  `tools/` (with consistent interface pattern)

### Phase 2: Environment Variables & XDG Compliance

**2.1 Update environment variable naming:**
- `DOTFILES`  `DEV_HOME`
- `DOTFILES_CONFIG`  `DEV_CONFIG`
- `DOTFILES_BIN`  `DEV_BIN`
- `DOTFILES_SCRIPTS`  split into `DEV_HOSTS` and `DEV_TOOLS`
- Add consistent `XDG_BIN_HOME` support

**2.2 Update shellenv command:**
- Export new variable names
- Maintain XDG compliance
- Update PATH construction
- Update profile sourcing

### Phase 3: Command Structure

**3.1 Simplify command interface:**

Keep these commands:
- `shellenv` - Export configuration for dev
- `status` - Show configuration status
- `init` - Init dev for shells
- `link` - Link configuration
- `unlink` - Unlink configuration
- `update` - Update dev
- `edit` - Edit dev in $EDITOR

Remove:
- `devtools` - merge functionality into main tool

Replace:
- `script`  `host` and `tool` subcommands

New commands:
- `dev host [platform]` - Run platform provisioning script
- `dev tool [tool_name]` - Run tool installation script
- Both commands list available options when run without args

### Phase 4: Tool Installation System

**4.1 Create unified tool installation pattern:**

Each tool script in `tools/` should support:
- `install` - Install the tool
- `uninstall` - Remove the tool
- `status` - Show if tool is installed
- `update` - Update the tool to latest version

**4.2 Tool design principles:**
- Platform-agnostic where possible
- Direct installation (no Homebrew dependency unless tool-specific)
- Portable installation to `$XDG_DATA_HOME` or `$XDG_BIN_HOME`
- Idempotent - safe to run multiple times
- POSIX-compliant shell scripts

**4.3 Merge toolchains into tools:**
- Convert `toolchains/*.sh`  `tools/*.sh`
- Maintain the install/uninstall/status/update interface
- Use same pattern for all language toolchains (Go, Node, Python, Ruby, Rust)

### Phase 5: Host Provisioning

**5.1 Separate platform provisioning:**
- Move platform scripts to `hosts/`: `macos.sh`, `fedora.sh`, `ubuntu.sh`
- Keep platform detection logic from `install.sh`
- Platform scripts should be minimal - just OS-level setup
- Platform scripts can call appropriate tools after base setup

**5.2 Host script responsibilities:**
- Install base OS packages
- Configure OS-level settings
- Install platform-specific tools
- Optionally call common tool installations

### Phase 6: Configuration Management

**6.1 Rename src to config:**
- `src/`  `config/`
- Update all references in main `bin/dev` tool
- Keep symlink management logic intact (it works well)
- Update sync() function source directory reference

### Phase 7: Documentation & Polish

**7.1 Update documentation:**
- Rewrite README.md for `dev` system
- Ensure ASSISTANT.md reflects new structure (already done)
- Update inline help text in all scripts
- Add migration guide from dotfiles (optional)

**7.2 Update installation scripts:**
- Update `install.sh` with new variables and paths
- Update `uninstall.sh` with new variables and paths
- Update repository URL references (if applicable)
- Update clone destination to use DEV_HOME

### Key Design Decisions

1. **Incremental migration**: Keep proven patterns from dotfiles
2. **Simplify**: Remove Homebrew as default dependency, make it optional tool
3. **Consistency**: All tools follow same interface pattern (install/uninstall/status/update)
4. **Portability**: Favor direct installation over package managers
5. **POSIX compliance**: All scripts use `#!/bin/sh`
6. **Idempotency**: All operations safe to repeat
7. **XDG compliance**: Use XDG directories throughout

### Files to Create/Modify

**Major changes:**
- Rename/modify: `bin/dotfiles`  `bin/dev` (major refactor)
- Remove: `bin/devtools` (merge functionality into dev)
- Modify: `install.sh`, `uninstall.sh` (variable names, paths)
- Move: `src/*`  `config/*` (directory rename)

**Reorganization:**
- Split: `scripts/*` into `hosts/*` and `tools/*`
- Merge: `toolchains/*`  `tools/*`

**Updates:**
- Update: `etc/profile` for new variable names
- Update: `README.md` (complete rewrite for dev system)
- Update: `ASSISTANT.md` (already updated)

### Implementation Order

We should implement in this order to maintain working state:

1. Phase 1.2 - Directory reorganization (create structure)
2. Phase 6.1 - Rename src to config
3. Phase 2 - Update environment variables
4. Phase 1.1 - Rename and update main tool
5. Phase 3 - Update command structure
6. Phase 4 - Unify tool installation system
7. Phase 5 - Finalize host provisioning
8. Phase 7 - Documentation and polish

### Analysis: dotfiles Repository

**Current structure:**
```
~/.local/share/dotfiles/
 bin/
    dotfiles (main tool - 342 lines)
    devtools (toolchain manager - 103 lines)
    [other utilities]
 src/ (config files)
 etc/ (shell profiles)
 scripts/ (mixed platform + tool scripts)
 toolchains/ (language toolchains: go, nodejs, python, ruby, rust)
 install.sh
 uninstall.sh
```

**Key patterns to preserve:**
- Symlink management system (sync function)
- Shell integration (shellenv, init)
- Status checking and conflict detection
- Logging functions (log, vlog, err)
- Idempotent script design
- Platform detection

**Key patterns from toolchains to apply to tools:**
- Each script takes action as first argument (install/uninstall/status/update)
- Consistent logging format
- Version checking
- Checksum verification where applicable
- Portable installation paths

### Next Steps

After committing this plan:
1. Start with Phase 1.2 - Create new directory structure
2. Move files to appropriate locations
3. Update references incrementally
4. Test after each phase

---

## Phase 1 Implementation Notes

### Design Decisions (2025-09-29)

**Shell Support:**
- **zsh only** - Drop bash support to simplify
- Update `init` command to only configure zsh
- Remove bash-specific logic from shell detection

**Command Naming:**
- Rename `shellenv` → `env` for brevity
- `dev env` is clearer and shorter than `dev shellenv`
- Group configuration symlink commands under `config` subcommand

### Updated Command Structure

**Core Commands:**
- `dev env` - Export configuration for dev environment (renamed from shellenv)
- `dev init` - Initialize dev for zsh only
- `dev update` - Update dev from git and re-link
- `dev edit` - Edit dev repository in $EDITOR

**Config Management (new subcommand):**
- `dev config status` - Show configuration status (symlinks)
- `dev config link` - Link configuration files
- `dev config unlink` - Unlink configuration files

**Provisioning Commands:**
- `dev host [platform]` - Run platform provisioning script
- `dev tool [tool_name] [action]` - Manage tool installation

**Rationale:**
- Groups related symlink operations under `config`
- Keeps top-level commands focused on high-level operations
- `status`, `link`, `unlink` are all about config file management

**Global Options:**
- `-d <directory>` - Specify dev directory (default: `$DEV_HOME`)
- `-t <directory>` - Specify target directory (default: `$HOME`)
- `-v` - Verbose output
- `-h` - Show help

**Environment Variables:**
- `DEV_HOME` - Location of dev repository (default: `$XDG_DATA_HOME/dev`)
- `DEV_CONFIG` - User config override (default: `$XDG_CONFIG_HOME/dev`)
- `DEV_BIN` - Dev bin directory (computed: `$DEV_HOME/bin`)
- `DEV_HOSTS` - Hosts directory (computed: `$DEV_HOME/hosts`)
- `DEV_TOOLS` - Tools directory (computed: `$DEV_HOME/tools`)
- `XDG_CONFIG_HOME` - Default: `$HOME/.config`
- `XDG_DATA_HOME` - Default: `$HOME/.local/share`
- `XDG_STATE_HOME` - Default: `$HOME/.local/state`
- `XDG_CACHE_HOME` - Default: `$HOME/.cache`
- `XDG_BIN_HOME` - Default: `$HOME/.local/bin`
- `TARGET` - Target for symlinks (default: `$HOME`)

### Phase 1.1 Completion Status

**Completed (2025-09-29):**

✅ Created `.editorconfig` (ported from dotfiles)
- 2-space indentation for most files
- Tab indentation for git/ssh config files
- UTF-8, LF line endings
- Trim trailing whitespace

✅ Created `bin/dev` scaffold with:
- All environment variable setup (XDG + DEV_*)
- Command line option parsing (-d, -t, -v, -h)
- Logging functions (log, vlog, err)
- Command structure with stubs for all commands
- Config subcommand with status/link/unlink actions
- Proper error handling for invalid commands/actions
- No modelines (using .editorconfig instead)

✅ Updated documentation:
- NOTES.md with Phase 1 implementation notes
- ASSISTANT.md with updated command structure and zsh-only note
- Both files reflect config subcommand design

**Testing Results:**
- All commands route correctly
- Config subcommand works with all actions (status, link, unlink)
- Error handling works (missing action, invalid action)
- Verbose flag works
- Option overrides work (-d, -t)
- Help output is clear and accurate

**Next Steps:**
- Phase 1.2: Create directory structure (bin/, config/, hosts/, tools/, docs/)
- Implement actual functionality for each command stub

---

## Command Implementation

### `dev env` - COMPLETED (2025-09-29)

Exports shell environment configuration for sourcing in shell profiles.

**Implementation:**
- Exports all XDG Base Directory variables with defaults
- Exports DEV_HOME and DEV_CONFIG with XDG-compliant defaults
- Adds XDG_BIN_HOME and DEV_HOME/bin to PATH
- Profile sourcing removed (will be addressed in zsh profile configuration later)

**Usage:**
```zsh
# In ~/.zshrc
eval "$(dev env)"
```

**Testing:**
- ✅ Generates correct export statements
- ✅ Works with eval in zsh
- ✅ Works when sourced in sh
- ✅ Sets all environment variables correctly
- ✅ Adds bin directories to PATH

---

### `dev config` - COMPLETED (2025-09-29)

Manages configuration file symlinks from `config/` to `$XDG_CONFIG_HOME`.

**Implementation:**
- Ported config files from dotfiles `src/.config/` to dev `config/`
- TARGET resolution: Always set first, XDG paths derived from TARGET
- Links everything under `config/` to `$TARGET/.config` (XDG_CONFIG_HOME)
- Three actions: status, link, unlink
- Supports -t option to test with temp directories without affecting $HOME

**Key Functions:**
- `setup_environment()` - Sets XDG and DEV variables based on TARGET
- `config_sync()` - Main sync engine (renamed from sync() for clarity)
- `config_usage()` - Usage display for config subcommand
- `check_symlink()` - Validates symlink targets
- `usage_options()` - Reusable options display (DRY)

**Directory Cleanup:**
- Iterative empty directory removal after unlink
- Safely preserves directories containing user files
- Handles cascading cleanup (parent dirs become empty after children removed)
- Tested with mixed user/managed content

**Testing:**
- ✅ Status shows missing/ok/conflict/invalid links
- ✅ Link creates all symlinks correctly
- ✅ Unlink removes symlinks and all empty directories
- ✅ Unlink preserves directories with user files
- ✅ -t option works to test without affecting $HOME
- ✅ Verbose mode shows all operations
- ✅ Respects EXCLUDE_PATTERNS (.DS_Store, etc.)
- ✅ Usage shows expanded path values
- ✅ Invalid actions show error then usage

**Config files ported:**
- ghostty, git, helix, homebrew, irb, karabiner, nano, readline, ssh, vim, zed

**Design Patterns Established:**
- `cmd_*` prefix for command handlers
- `*_usage` for usage functions
- `*_sync` or similar for helper functions
- Subcommand usage shows full command path (e.g., "dev config")
- Error messages follow pattern: "command: error message"
---

## ZSH Shell Integration Analysis

### ZDOTDIR Research

**What is ZDOTDIR?**
- Environment variable that tells zsh where to find startup files
- Default: `$HOME` (looks for ~/.zshrc, ~/.zshenv, etc.)
- When set: zsh looks for startup files in `$ZDOTDIR` instead
- Exception: `~/.zshenv` is ALWAYS sourced first (before ZDOTDIR is evaluated)

**ZSH Startup File Order:**
1. `~/.zshenv` - Always sourced (can't be moved with ZDOTDIR)
2. `$ZDOTDIR/.zprofile` - Login shells
3. `$ZDOTDIR/.zshrc` - Interactive shells
4. `$ZDOTDIR/.zlogin` - Login shells (after zshrc)
5. `$ZDOTDIR/.zlogout` - Login shells on exit

### Option Analysis

**Option 1: ZDOTDIR in $TARGET/.config/zsh (symlink approach)**
```
config/zsh/.zshrc        → symlinked to → $TARGET/.config/zsh/.zshrc
~/.zshenv sets ZDOTDIR=$XDG_CONFIG_HOME/zsh
```
Pros:
- XDG compliant
- Consistent with other config/ files (managed via `dev config`)
- Clean separation of dev-managed vs user-managed
- Easy to version control

Cons:
- Requires ~/.zshenv to set ZDOTDIR (bootstrap file in $HOME)
- One extra level of indirection

**Option 2: Direct ZDOTDIR to $DEV_HOME/etc (no symlinks)**
```
$DEV_HOME/etc/zshrc      → ZDOTDIR=$DEV_HOME/etc
~/.zshenv sets ZDOTDIR=$DEV_HOME/etc
```
Pros:
- Direct access (no symlinks)
- Matches dotfiles pattern
- Could include profile.d modular structure

Cons:
- Not XDG compliant
- Breaks pattern of config/ being the single source of config files
- Mixing shell config with potential shell profiles/utilities

### Recommendation: Option 1 (ZDOTDIR in config/zsh)

**Rationale:**
1. **XDG Compliance** - Keeps everything under `$XDG_CONFIG_HOME`
2. **Consistency** - All managed configs go through `dev config link`
3. **Clean Separation** - Clear boundary between dev-managed and user files
4. **Standard Practice** - This is the modern zsh convention
5. **Flexibility** - Users can add their own files to `~/.config/zsh/` that won't be managed

**Implementation:**
```
Structure:
  config/zsh/.zshenv      # Minimal - just sets ZDOTDIR
  config/zsh/.zshrc       # Main interactive shell config
  config/zsh/.zprofile    # Login shell config (optional)
  config/zsh/functions/   # Custom functions (optional)

Bootstrap:
  ~/.zshenv -> symlinked to -> $XDG_CONFIG_HOME/zsh/.zshenv

Flow:
  1. zsh starts, sources ~/.zshenv (ALWAYS)
  2. ~/.zshenv sets ZDOTDIR=$XDG_CONFIG_HOME/zsh
  3. zsh then sources $ZDOTDIR/.zshrc (for interactive shells)
```

**What `dev init` needs to do:**
1. Create config/zsh/.zshenv with minimal bootstrap:
   ```zsh
   export ZDOTDIR=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
   ```
2. Symlink ~/.zshenv -> $XDG_CONFIG_HOME/zsh/.zshenv
3. Add `eval "$(dev env)"` to config/zsh/.zshrc
4. Run `dev config link` to link all config files

---

## ZSH Shell Integration - COMPLETED (2025-09-30)

### Implementation

**Decision:** Simplified approach - single line in ~/.zshenv that evaluates `dev env`

**Structure:**
```
~/.zshenv                       # Bootstrap: eval "$(dev env)"
config/zsh/.zshrc              # Main zsh config
config/zsh/.zprofile           # Login shell config
config/zsh/profile.d/*.sh      # Environment setup (homebrew, ssh)
config/zsh/rc.d/*.sh           # Runtime config (aliases, prompt, language tools)
```

**Bootstrap Flow:**
1. `~/.zshenv` runs: `eval "$(dev env)"`
2. `dev env` exports all XDG variables, DEV_HOME, and **ZDOTDIR**
3. zsh uses ZDOTDIR to find `.zshrc` in `$XDG_CONFIG_HOME/zsh/`
4. `.zshrc` loads modules from `profile.d/` and `rc.d/`

**Implementation Details:**
- `dev env` exports `ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}`
- `dev init` writes bootstrap line to `~/.zshenv` (idempotent)
- Ported all zsh config from dotfiles
- Removed all bash alternatives (zsh-only)
- Removed all vim modelines (use .editorconfig)
- Organized into profile.d (environment) and rc.d (runtime)

**Testing:**
- ✅ `dev init` creates/updates ~/.zshenv correctly
- ✅ ZDOTDIR is set and zsh finds config
- ✅ All rc.d modules load correctly
- ✅ Prompt, aliases, completions all working

---

## Host Provisioning System - COMPLETED (2025-09-30)

### Implementation

**Approach:** Fully idempotent scripts - no separate provision/update actions

**Command:**
```bash
dev host    # Auto-detects platform and runs provisioning
```

**Host Scripts:**
- `hosts/macos.sh` - Xcode CLI tools, Homebrew, Brewfile, system settings
- `hosts/fedora.sh` - Firmware updates, rpm-ostree/dnf, flatpak, GNOME/COSMIC settings
- `hosts/ubuntu.sh` - apt packages, updates, cleanup

**Design Decisions:**
1. **Platform auto-detection only** - No manual platform override needed
2. **Fully idempotent** - Check state, install missing, update existing in one run
3. **No provision/update split** - Eliminated duplication
4. **Consistent messaging** - Show "OK" for already-installed components

**Benefits:**
- Simple interface: just `dev host`
- Scripts adapt to current system state
- No redundant code paths
- Single source of truth

**Testing:**
- ✅ macOS provisioning works (Xcode, Homebrew, Brewfile)
- ✅ Auto-detection works correctly
- ✅ Idempotent - safe to run multiple times
- ✅ brew bundle check runs every time (fixes duplication issue)

---

## Installation Scripts - COMPLETED (2025-09-30)

### Implementation

**Scripts:**
- `install.sh` - Clone repo, init shell, link configs, optionally run host provisioning
- `uninstall.sh` - Unlink configs, clean up ~/.zshenv, remove directories

**Features:**
- Platform detection
- Git dependency checking with auto-install prompts
- Interactive prompts for host provisioning
- Support for branch selection (-b)
- Support for custom directories (-d, -t)

**Testing:**
- ✅ Scripts created and executable
- ✅ Match patterns from dotfiles

---

## Tools System - COMPLETED (2025-09-30)

### Implementation

**Approach:** Structured tools with install/update/uninstall/status actions

**Command:**
```bash
dev tool                    # List available tools
dev tool <name>            # Show tool status (default)
dev tool <name> install    # Install the tool
dev tool <name> update     # Update the tool
dev tool <name> uninstall  # Remove the tool
dev tool <name> status     # Show tool status
```

**Tools Ported (11 total):**

*Language Toolchains (5):*
- rust.sh - Rust via rustup
- ruby.sh - Ruby via rbenv
- go.sh - Go language toolchain
- python.sh - Python via uv
- nodejs.sh - Node.js via fnm

*Package Managers (2):*
- homebrew.sh - Homebrew for macOS/Linux
- flatpak.sh - Flatpak for Linux

*Applications (3):*
- claude.sh - Claude Code CLI
- tailscale.sh - Tailscale VPN client
- zed.sh - Zed editor

*Utilities (1):*
- ubi.sh - GitHub release binary installer

**Scripts Directory (9 utility/config scripts):**
- Configuration: github.sh, gpg.sh, ssh.sh
- Backup/Restore: gpg-backup.sh, gpg-restore.sh
- Specialized: ssh-yk.sh, yubico.sh, tailnet.sh, steam.sh

**Design Decisions:**
1. **Structured actions** - Each tool implements relevant actions (install/update/uninstall/status)
2. **Flexible interface** - Tools self-document which actions they support
3. **Separate scripts/** - Configuration and specialized scripts go in scripts/ directory
4. **Package managers as tools** - homebrew and flatpak are tools, not host-level
5. **Host integration** - Host scripts use tools when available with fallbacks

**Host Script Updates:**
- macOS uses `dev tool homebrew install` when available
- Fedora uses `dev tool flatpak update` when available
- Both have fallbacks for bootstrap scenarios

**Testing:**
- ✅ dev tool command lists all 11 tools
- ✅ Tool status checking works
- ✅ Homebrew tool adapted with full action support
- ✅ Flatpak tool created with full action support
- ✅ Host scripts integrate with tools system

---

## Script Runner System - COMPLETED (2025-09-30)

### Implementation

**Command:**
```bash
dev script                    # List available scripts
dev script <name>             # Run a script
dev script <name> -- <args>   # Run a script with arguments
```

**Features:**
- Run scripts from anywhere (not just DEV_HOME)
- Scripts executed with `sh` for consistency
- Argument passing via `--` separator
- Lists all available scripts when no name provided
- Error handling for missing/non-executable scripts

**Scripts:**
- gitconfig.sh - Generate machine-specific git configuration (new)
- github.sh, gpg.sh, ssh.sh - Configuration scripts
- gpg-backup.sh, gpg-restore.sh - Backup/restore utilities
- ssh-yk.sh, yubico.sh, tailnet.sh, steam.sh - Specialized setup

**gitconfig.sh Details:**
- Simplified from dotfiles version
- Uses `git config --global` directly
- Assumes gh CLI for GitHub (required)
- Keeps GCM Azure DevOps configuration (work requirement)
- Supports GPG commit signing with YubiKey
- Targets ~/.gitconfig (machine-specific config)
- Machine-independent config in $XDG_CONFIG_HOME/git/config

**Testing:**
- ✅ `dev script` lists all 10 scripts
- ✅ `dev script gitconfig` runs successfully
- ✅ Script runner works from any directory
- ✅ Help system works correctly

---

## Important Reminders

### Usage Alignment
**CRITICAL:** Always verify usage output alignment when adding new commands.

**Current Configuration:**
- Field width: `%-26s` via `DEVLOG_WIDTH=26` (bin/dev:19)
- Longest label: "script [name] [-- args]" = 24 characters
- Must have 2+ chars padding after longest label

**Verification Steps:**
1. After adding/modifying commands, run: `./bin/dev -h`
2. Check that all descriptions align vertically
3. If misaligned, increase `DEVLOG_WIDTH` value in bin/dev
4. Test all subcommand help too (`dev config -h`, `dev tool -h`, etc.)

**Example of correct alignment:**
```
Commands:
  env                     Export configuration for dev environment
  script [name] [-- args] Run utility script
```

**Why This Matters:**
- Professional appearance
- Easy to read and scan
- User experience quality signal

---

## Standardized Logging System - COMPLETED (2025-09-30)

### bin/devlog - Sourceable Library

**Evolution:**
1. **Initial Implementation:** Standalone binary called via subprocess
2. **Performance Issue:** Subprocess overhead for every log call
3. **Refactor:** Converted to sourceable library with dual-mode support
4. **Result:** 2x performance improvement by eliminating subprocess calls

**Dual-Mode Design:**
```sh
# Mode 1: Source as library (preferred for performance)
. "$(dirname "$0")/../bin/devlog"
log info "install" "Installing package"

# Mode 2: Execute standalone (for quick testing)
devlog info "install" "Installing package"
```

**Implementation Details:**
- Uses `DEVLOG_SOURCED` flag to prevent multiple sourcing
- Detects execution vs sourcing via `${0##*/}` pattern
- Configurable field width via `DEVLOG_WIDTH` environment variable
- Default field width: 16 characters (override in sourcing script)

**Log Levels:**
- `info` - Default level, normal output
- `warn` - Warning messages (yellow text)
- `error` - Error messages (red text, stderr)
- `debug` - Verbose logging (only when `VERBOSE=1`)

**Usage Patterns:**
```sh
# Source devlog library for performance
. "$(dirname "$0")/../bin/devlog"

# Then use log function directly
log info "install" "Installing package"      # Info (default)
log warn "deprecated" "Feature deprecated"   # Warning
log error "failed" "Installation failed"     # Error
log debug "trace" "Debug information"        # Only if VERBOSE=1
log "simple" "Just a message"                # Info without explicit level
log "label" ""                               # Single line, no message
log ""                                       # Empty line
```

**Custom Field Width:**
```sh
# Override field width for wider labels
DEVLOG_WIDTH=26
. "$(dirname "$0")/devlog"
```

**Integration Pattern:**
All scripts now follow this pattern for consistent logging:
```sh
#!/bin/sh

# Source devlog library for performance
. "$(dirname "$0")/../bin/devlog"

install() {
  if command -v tool >/dev/null 2>&1; then
    log info "tool" "already installed, skipping"
    return 0
  fi

  log info "tool" "installing..."
  # ... installation code
  log info "tool" "installation complete"
}

status() {
  if command -v tool >/dev/null 2>&1; then
    log info "tool" "installed, version: ${version}"
  else
    log info "tool" "not installed"
  fi
}
```

**Migration Summary:**
All scripts migrated to use devlog library:
- ✅ bin/dev (with DEVLOG_WIDTH=26)
- ✅ install.sh (with fallback for bootstrap)
- ✅ uninstall.sh
- ✅ hosts/macos.sh, hosts/fedora.sh, hosts/ubuntu.sh
- ✅ All 11 tool scripts (flatpak, go, homebrew, nodejs, python, ruby, rust, claude, tailscale, zed, ubi)
- ✅ scripts/gitconfig.sh (10 scripts total in scripts/)

**Benefits:**
- Eliminates code duplication
- 2x performance improvement
- Consistent output formatting
- Centralized color/style management
- Easy to maintain and extend

---

## Enhanced Tool Command Features - COMPLETED (2025-09-30)

### Help Command Support
All subcommands now support help via:
```bash
dev config -h        # or --help, or help
dev host -h
dev tool -h
dev script -h
```

Pattern used in all command handlers:
```sh
case "${1:-}" in
help | -h | --help)
  command_usage
  return 0
  ;;
esac
```

### Show All Tools Status
`dev tool` with no arguments (or `dev tool status`) now shows status of all tools:
```bash
dev tool          # Shows status of all 11 tools
dev tool status   # Same as above
```

Implementation:
- Loops through all `tools/*.sh` scripts
- Checks if script is executable
- Checks if script has `status()` function
- Calls `status` action for each tool
- Shows warnings for legacy scripts without status support

**Benefits:**
- Quick overview of entire toolchain status
- Easy to see what's installed vs missing
- Consistent interface across all tools

### claude.sh and zed.sh Enhancements
Both tools now have full CRUD operations:

**claude.sh:**
- `install` - Install via official script (idempotent)
- `update` - Self-update via `claude update`
- `uninstall` - Remove binary and ~/.claude directory
- `status` - Show version, path, and data directory size
- Note: Claude hardcodes ~/.claude for data (not XDG compliant)

**zed.sh:**
- `install` - Install via official script (idempotent)
- `update` - Reinstall to ensure latest (Zed auto-updates itself)
- `uninstall` - Remove app bundle and CLI symlink (both macOS and Linux)
- `status` - Show version, channel (stable/preview), and app path
- Internal `_do_install()` function to bypass "already installed" check for updates

**Pattern:**
Both tools follow standardized structure:
```sh
#!/bin/sh

. "$(dirname "$0")/../bin/devlog"

install() {
  if command -v tool >/dev/null 2>&1; then
    log info "tool" "already installed, skipping"
    status
    return 0
  fi

  log info "tool" "installing..."
  # ... installation
  log info "tool" "installation complete"
}

update() { ... }
uninstall() { ... }
status() { ... }

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
```

---

## Pending Work

### dev update Command
**Status:** Stub exists in bin/dev:256-259, not yet implemented

**Requirements:**
- Pull latest changes from git
- Re-run `dev config link` to sync any new config files
- Show summary of what was updated
- Handle merge conflicts gracefully

**Implementation Notes:**
```sh
cmd_update() {
  if [ ! -d "$DEV_HOME/.git" ]; then
    err "DEV_HOME is not a git repository: $DEV_HOME"
    exit 1
  fi

  log "update" "Pulling latest changes from git"
  cd "$DEV_HOME" || exit 1
  git pull || { err "Git pull failed"; exit 1; }

  log "update" "Re-linking configuration files"
  config_sync "link"

  log "update" "Update complete"
}
