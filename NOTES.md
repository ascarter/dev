# Development Notes

## Current Status (2025-10-01)

The `dev` system is fully functional with all core features implemented.

### Completed Systems
- ✅ Core structure (bin/dev with full command interface)
- ✅ Configuration management (dev config)
- ✅ Shell integration (zsh via ZDOTDIR)
- ✅ Host provisioning (fully idempotent macos/fedora/ubuntu)
- ✅ Tools system (11 tools with install/update/uninstall/status)
- ✅ Scripts system (10 utility/config scripts)
- ✅ Application management (manifest-based with UBI/DMG/Flatpak backends)
- ✅ Logging library (sourceable lib/log.sh for performance)
- ✅ Documentation (app-management.md, bootstrap.md)

## Recent Changes

### Application Management System
**Major architectural change:** Moved from individual tool scripts to declarative TOML manifests for CLI tools.

**Removed Scripts:**
- `tools/helix.sh` → `hosts/cli.toml`
- `tools/gh.sh` → `hosts/cli.toml`
- `tools/codex.sh` → `hosts/cli.toml`
- `tools/cosign.sh` → `hosts/cli.toml`

**New Components:**
- `lib/app.sh` - Main app management module
- `lib/app/ubi.sh` - UBI installer backend with symlink management
- `lib/app/dmg.sh` - DMG installer backend for macOS
- `lib/app/flatpak.sh` - Flatpak installer backend for Linux
- `lib/toml.sh` - Shell-based TOML parser (fallback)
- `hosts/cli.toml` - Cross-platform CLI tools manifest (20+ tools)
- `hosts/macos.toml` - macOS-specific apps (DMG installers)
- `hosts/linux.toml` - Linux-specific apps (Flatpak)

**Commands:**
```bash
dev app install <name>     # Install specific app
dev app install            # Install all apps (--all removed, now default)
dev app status             # Show status of all apps
dev app update <name>      # Update specific app
dev app list               # List all apps in manifests
```

**Key Features:**
- Multi-manifest support (cli.toml + platform-specific)
- Smart binary detection for platform-specific variants
- Symlink management for completions and man pages
- Idempotent installs (skip already-installed apps)
- Update support with force reinstall

### Bootstrap Dependencies
**Two-stage installation pattern:**
1. Bootstrap: Minimal binary-only (ubi, yq)
2. Full install: Complete with man pages via manifests

**install.sh automatically:**
- Installs ubi via `dev tool ubi install`
- Installs yq binary via ubi for TOML parsing
- User can upgrade to full installs later

### Logging System Evolution
**Performance improvement:** Converted bin/devlog to sourceable lib/log.sh
- Eliminates subprocess overhead (2x performance improvement)
- Dual-mode design (source as library or execute standalone)
- Configurable field width via DEVLOG_WIDTH
- All scripts migrated to use library

## Pending Work

### dev update Command
**Status:** Stub exists in bin/dev, not yet implemented

**Requirements:**
- Pull latest changes from git
- Re-run `dev config link` to sync any new config files
- Show summary of what was updated
- Handle merge conflicts gracefully

**Implementation:**
```sh
cmd_update() {
  if [ ! -d "$DEV_HOME/.git" ]; then
    log error "not a git repository" "$DEV_HOME"
    exit 1
  fi

  log info "update" "Pulling latest changes from git"
  cd "$DEV_HOME" || exit 1
  git pull || { log error "git pull failed" ""; exit 1; }

  log info "update" "Re-linking configuration files"
  config_sync "link"

  log info "update" "Update complete"
}
```

### Potential Future Enhancements

**Application Management:**
- Support for Homebrew cask apps in manifests
- Version pinning for reproducible environments
- Dependency resolution between apps
- Manifest validation before install

**Configuration:**
- Template support for machine-specific configs
- Encrypted secret management
- Config validation

**Tools:**
- More language toolchains (Elixir, Java, etc.)
- Container runtimes (Docker, Podman)
- Cloud CLIs (aws, gcloud, azure)

**Documentation:**
- Migration guide from dotfiles
- Video walkthrough
- Architecture diagrams

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

### Code Quality Standards
- DRY within reason - don't sacrifice readability
- POSIX-compliant shell syntax (`#!/bin/sh`)
- All scripts must be idempotent
- No emojis or excessive colors in output
- Prefer bold/italic over colors
- Use .editorconfig settings instead of modelines
- Never hardcode secrets or personal identifiers
- All scripts source lib/log.sh for consistent logging

## Testing Notes

### Manual Test Checklist
Before major commits, test:
- [ ] `dev -h` - Help alignment
- [ ] `dev env` - Environment export
- [ ] `dev init` - Shell initialization
- [ ] `dev config status` - Symlink status
- [ ] `dev config link` - Symlink creation
- [ ] `dev config unlink` - Symlink removal
- [ ] `dev host` - Platform provisioning
- [ ] `dev tool` - Tool status for all
- [ ] `dev tool <name> status` - Individual tool status
- [ ] `dev script` - Script listing
- [ ] `dev app list` - App listing
- [ ] `dev app status` - All apps status
- [ ] `dev app install <name>` - Single app install
- [ ] `dev app update <name>` - Single app update

### Platform Testing
- macOS (primary platform)
- Fedora (Linux target)
- Ubuntu (Linux target)

## Documentation

### Reference Documentation (docs/)
- `docs/app-management.md` - Complete application management guide
- `docs/bootstrap.md` - Bootstrap process and dependencies

### Architectural Documentation
- `ASSISTANT.md` - AI assistant guidance and system overview
- `README.md` - User-facing documentation and quick start

### This File (NOTES.md)
- Current work and progress tracking
- Implementation decisions and rationale
- Pending work and future enhancements
