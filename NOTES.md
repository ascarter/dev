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