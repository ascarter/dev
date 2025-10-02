# Bootstrap Process

This document explains how the `dev` environment bootstraps itself and manages its dependencies.

## Overview

The bootstrap process is designed to be minimal and self-contained, requiring only basic system tools (git, curl/wget) to get started. Once bootstrapped, the system can manage all other dependencies declaratively through TOML manifests.

## Bootstrap Dependencies

### System Requirements

The following must be available on the system before running `install.sh`:

1. **git** - Required to clone the repository
   - macOS: Installed via Xcode Command Line Tools
   - Linux: Installed via package manager (apt, dnf, etc.)

2. **curl or wget** - Only needed for one-line install
   - Pre-installed on most systems

### Bootstrap Tools

The installer automatically installs these tools if not present:

1. **ubi** (Universal Binary Installer)
   - Purpose: Install CLI tools from GitHub releases
   - Source: GitHub releases (houseabsolute/ubi)
   - Installation: Via `dev tool ubi install` (uses bundled script)
   - Location: `${XDG_BIN_HOME}/ubi`

2. **yq** (TOML/YAML/JSON Parser)
   - Purpose: Parse TOML manifests for app management
   - Source: GitHub releases (mikefarah/yq)
   - Bootstrap: Minimal binary-only install via ubi
   - Location: `${XDG_BIN_HOME}/yq`
   - Full Install: Available via `dev app install yq` (adds man pages)

## Installation Flow

### 1. Initial Bootstrap

```bash
sh -c "$(curl -sSL https://raw.githubusercontent.com/ascarter/dev/main/install.sh)"
```

**What happens:**
1. Detects platform (macOS, Linux distribution)
2. Checks for git, prompts to install if missing
3. Clones repository to `${DEV_HOME}` (default: `~/.local/share/dev`)
4. Runs `dev init` - Creates `~/.zshenv` with XDG environment setup
5. Runs `dev config link` - Symlinks configuration files

### 2. Dependency Bootstrap

**ubi installation:**
```bash
dev tool ubi install
```
- Installs ubi binary to `${XDG_BIN_HOME}`
- Uses bundled script that downloads and installs appropriate binary for platform
- No external dependencies required

**yq installation (minimal):**
```bash
ubi --project mikefarah/yq --in ${XDG_BIN_HOME}
```
- Downloads yq binary directly to `${XDG_BIN_HOME}`
- Binary-only install (no man pages or extras)
- Sufficient for manifest parsing
- User can upgrade to full install later

### 3. Host Provisioning (Optional)

The installer prompts to run platform-specific provisioning:

```bash
./hosts/macos.sh      # macOS
./hosts/fedora.sh     # Fedora
./hosts/ubuntu.sh     # Ubuntu
```

These scripts install platform-specific packages and configure system settings.

### 4. Application Installation (Post-Bootstrap)

After bootstrap, users can install applications from manifests:

```bash
# List available applications
dev app list

# Install specific application
dev app install yq        # Full install with man pages

# Install all applications
dev app install --all
```

## Two-Stage Installation Pattern

Some tools use a two-stage installation pattern:

### Stage 1: Bootstrap (Minimal)
- Installs bare minimum to make the tool functional
- Goal: Get the system working quickly
- Example: `yq` binary only

### Stage 2: Full Install (Complete)
- Installs all extras (man pages, completions, runtime files)
- Managed declaratively through manifests
- Example: `dev app install yq`

### Why Two Stages?

1. **Faster Bootstrap**: Get system operational quickly
2. **Simpler Bootstrap Code**: No complex symlink management in install.sh
3. **Declarative Management**: Full installs defined in manifests
4. **Consistent Pattern**: Same installation method for all apps
5. **Flexibility**: Users can skip full installs if not needed

## Dependency Graph

```
System (git, curl)
    ↓
install.sh (clone repo)
    ↓
dev tool ubi install
    ↓
ubi --project mikefarah/yq (bootstrap)
    ↓
dev app install (uses yq for TOML parsing)
    ↓
Applications from manifests (cli.toml + platform.toml)
```

## yq Bootstrap Details

### Why yq?

Previously, the system used a shell-based TOML parser with limitations:
- No multi-line array support
- Limited error handling
- Fragile string parsing
- Hard to maintain

Using `yq` provides:
- Full TOML specification support
- Robust error messages
- Well-tested and maintained
- Support for multiple formats (TOML, YAML, JSON, XML)

### Bootstrap Install

**Location:** `${XDG_BIN_HOME}/yq`

**Command:**
```bash
ubi --project mikefarah/yq --in ${XDG_BIN_HOME}
```

**What it does:**
- Downloads latest yq release for current platform
- Extracts yq binary
- Places in `${XDG_BIN_HOME}`
- No symlinks, no man pages

### Full Install

**Location:** `${XDG_DATA_HOME}/yq/`

**Command:**
```bash
dev app install yq
```

**Manifest (hosts/cli.toml):**
```toml
[yq]
installer = "ubi"
project = "mikefarah/yq"
extract_all = true
# Symlinks auto-detect platform-specific binaries (yq_darwin_arm64, yq_linux_amd64, etc.)
symlinks = ["yq:${XDG_BIN_HOME}/yq", "yq.1:${XDG_DATA_HOME}/man/man1/yq.1"]
```

**What it does:**
- Downloads and extracts full yq archive
- Auto-detects platform-specific binary name (e.g., `yq_darwin_arm64`)
- Creates symlinks for binary and man page
- Man page accessible via `man yq`
- Replaces bootstrap binary with proper installation

**Multi-Manifest System:**

The app management system uses multiple manifest files:
- `hosts/cli.toml` - Shared CLI tools (cross-platform)
- `hosts/macos.toml` - macOS-specific apps (DMG installers)
- `hosts/linux.toml` - Linux-specific apps (Flatpak)

When you run `dev app install`, both the shared CLI manifest and platform-specific manifest are loaded. This eliminates duplication while allowing platform-specific overrides.

## Environment Setup

### XDG Base Directory Specification

The system follows XDG conventions:

```bash
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}
XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
```

### PATH Configuration

`~/.zshenv` is created with:
```zsh
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

export PATH="${XDG_BIN_HOME}:${PATH}"
export DEV_HOME="${XDG_DATA_HOME}/dev"

# Source dev environment
[[ -f "${DEV_HOME}/config/zsh/.zshenv" ]] && . "${DEV_HOME}/config/zsh/.zshenv"
```

### MANPATH Configuration

`config/zsh/rc.d/manpath.sh`:
```zsh
# Add XDG_DATA_HOME/man to MANPATH for locally installed man pages
if [[ -d "${XDG_DATA_HOME}/man" ]]; then
  export MANPATH="${XDG_DATA_HOME}/man:${MANPATH}"
fi
```

This enables `man yq` and other locally installed man pages.

## Troubleshooting Bootstrap

### Git Not Found

**Error:** `git: command not found`

**Solution:**
- macOS: `xcode-select --install`
- Ubuntu/Debian: `sudo apt install git`
- Fedora: `sudo dnf install git`

### ubi Installation Failed

**Error:** `dev tool ubi install` fails

**Solution:**
1. Check internet connection
2. Verify platform is supported (macOS, Linux)
3. Check `${XDG_BIN_HOME}` exists and is writable
4. Review error messages in output

### yq Installation Failed

**Error:** `ubi --project mikefarah/yq` fails

**Solution:**
1. Verify ubi is installed: `command -v ubi`
2. Check internet connection to GitHub
3. Verify `${XDG_BIN_HOME}` exists and is writable
4. Try manual install: Download from https://github.com/mikefarah/yq/releases

### yq Not in PATH

**Error:** `yq: command not found` after bootstrap

**Solution:**
1. Verify yq exists: `ls -l ${XDG_BIN_HOME}/yq`
2. Check PATH includes XDG_BIN_HOME: `echo $PATH`
3. Reload shell: `exec zsh` or open new terminal
4. Verify ~/.zshenv sources dev environment

## Post-Bootstrap

After successful bootstrap:

1. **Reload Shell**
   ```bash
   exec zsh
   # or open a new terminal
   ```

2. **Verify Installation**
   ```bash
   dev --version
   ubi --version
   yq --version
   ```

3. **Install Applications**
   ```bash
   dev app list              # See available apps (from cli.toml + platform.toml)
   dev app install yq        # Full yq with man pages
   dev app install --all     # Install everything from both manifests
   ```

4. **Customize**
   - Edit `hosts/cli.toml` for cross-platform CLI tools
   - Edit `hosts/<platform>.toml` for platform-specific apps
   - Modify configuration files in `config/`
   - Add custom scripts to `bin/`

## See Also

- [App Management System](app-management.md) - Declarative application management
- [Configuration Management](../README.md#configuration-management) - Config file management
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)