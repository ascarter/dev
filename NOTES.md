# Development Notes

## Current Status (2025-10-02)

The `dev` system is fully functional with all core features implemented.

### Completed Systems
- ✅ Core structure (bin/dev with full command interface)
- ✅ Configuration management (dev config)
- ✅ Shell integration (zsh via ZDOTDIR)
- ✅ Host provisioning (fully idempotent macos/fedora/ubuntu)
- ✅ Tools system (11 tools with install/update/uninstall/status)
- ✅ Scripts system (10 utility/config scripts)
- ✅ Application management (manifest-based with UBI/DMG/Flatpak/Curl backends)
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
- `tools/claude.sh` → `hosts/cli.toml`
- `tools/zed.sh` → `hosts/macos.toml` + `hosts/linux.toml`

**New Components:**
- `lib/app.sh` - Main app management module
- `lib/app/ubi.sh` - UBI installer backend with symlink management
- `lib/app/dmg.sh` - DMG installer backend for macOS
- `lib/app/flatpak.sh` - Flatpak installer backend for Linux
- `lib/app/curl.sh` - Curl installer backend for curl-piped install scripts
- `lib/toml.sh` - Shell-based TOML parser (fallback)
- `hosts/cli.toml` - Cross-platform CLI tools manifest (20+ tools)
- `hosts/macos.toml` - macOS-specific apps (DMG, Curl installers)
- `hosts/linux.toml` - Linux-specific apps (Flatpak, Curl installers)

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
- Consistent installation: All UBI tools extract to $XDG_DATA_HOME/<app>
- Flexible bin symlinking with :alias support
- Smart binary detection for platform-specific variants
- Idempotent installs (skip already-installed apps)
- Update support with force reinstall
- Self-update flag for apps with built-in update mechanisms
- Smart defaults for shell and check_cmd
- Flexible uninstall_cmd for custom uninstall logic
- `dev doctor` command for environment health checks

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

### Future Direction: Shell vs Rust

**Current State (2025-10-02):**
The system is implemented in POSIX shell scripts, which provides:
- Instant hackability (edit → test, no compile cycle)
- Transparency (easy to understand what's happening)
- Zero compilation overhead
- Works everywhere with just sh/bash

**Question: Are we building a package manager?**
- Not quite - no dependency resolution, version constraints, or repositories
- More accurate: Personal environment manager that happens to install tools
- Focus: Declarative manifest of "what I want installed" + dotfile management
- User-scoped, XDG-compliant, platform-aware

**Comparison to existing tools:**
- Homebrew: System-wide, complex dependency graphs, hundreds of maintainers
- Mise/asdf: Runtime version management, tasks, plugins - different focus
- Nix/Home Manager: Much heavier, steep learning curve
- Chezmoi: Dotfiles only, no app installation
- **Our niche**: Combines dotfiles + app installation + shell config in one focused system

**Rust migration considerations:**

*Pros:*
- 10-50x faster manifest parsing (native TOML, no yq subprocess)
- 2-5x faster status checks (parallel operations, no process spawns)
- UBI as a library (built-in, no subprocess overhead)
- Version checking without spawning processes
- Better error handling (Result types vs shell)
- Type-safe manifest validation
- Structured logging and progress bars
- GitHub releases → single binary distribution
- Profiles feature becomes natural to implement

*Cons:*
- Loss of instant hackability (edit → compile → test cycle)
- Need to learn/maintain Rust code
- Current system works well
- Some platform-specific operations still need shell (DMG mounting, etc.)

**Translation difficulty:**
- Core functionality: 2-3 weeks (experienced Rust developer)
- Feature parity: 4-6 weeks
- Polish + testing: +2 weeks

**Key crates:**
- clap (CLI), serde/toml (config), tokio (async), ubi (library)
- anyhow (errors), indicatif (progress), git2, directories

**Profile concept (compelling for Rust):**
```bash
dev profile clone codespaces/python-ml
dev profile activate python-ml
# → Clones config repo, installs manifests, links configs
```

Benefits:
- Different tool sets for different contexts (work/personal/project)
- Perfect for Codespaces/Toolbox containers
- Easy in Rust, hard in shell

**Decision: Hybrid approach**
1. Continue in shell for now (working, making progress)
2. Design with Rust in mind (modular architecture, TOML manifests)
3. Prototype Rust version when:
   - Performance becomes an issue
   - Profiles feature is strongly desired
   - Time available to learn/experiment
4. Could keep both: Rust core + shell for platform-specific operations

**Bottom line:**
The manifest format and architecture are the hard parts. Implementation language is just details. Current shell implementation is winning on hackability. Rust would win on performance and advanced features (profiles, parallel ops, version checking).

### Potential Future Enhancements

**Application Management:**
- Version pinning for reproducible environments
- Dependency resolution between apps
- Manifest validation before install
- Parallel installation (easier in Rust)

**Configuration:**
- Template support for machine-specific configs
- Encrypted secret management
- Config validation
- Profile system (work/personal/project contexts)

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
