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
