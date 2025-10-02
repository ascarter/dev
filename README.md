# dev

A personal developer environment management system for macOS and Linux.

## Overview

`dev` manages configuration files, development tools, and system provisioning across platforms. It uses symlinks for configuration management and provides idempotent provisioning scripts that can be run multiple times safely.

**Key Features:**
- **Configuration Management** - Symlink-based config file management with conflict detection
- **Host Provisioning** - Platform-specific setup (macOS, Fedora, Ubuntu) with automatic updates
- **Tool Installation** - Manage development tools (languages, package managers, applications)
- **Shell Integration** - ZSH-focused with automatic environment setup
- **XDG Compliant** - Follows XDG Base Directory Specification
- **Idempotent** - All operations can be run multiple times safely

## Installation

### Quick Install (Recommended)

Bootstrap a new machine with a single command:

```bash
sh -c "$(curl -sSL https://raw.githubusercontent.com/ascarter/dev/main/install.sh)"
```

Install from a specific branch:

```bash
sh -c "$(curl -sSL https://raw.githubusercontent.com/ascarter/dev/main/install.sh)" -s -- -b <branch>
```

### Manual Install

If you prefer not to pipe to shell, clone the repository first:

```bash
git clone https://github.com/ascarter/dev.git ~/.local/share/dev
cd ~/.local/share/dev
./install.sh
```

### What the Installer Does

1. Installs git if not present (prompts for platform-specific installation)
2. Clones the repository to `$HOME/.local/share/dev`
3. Initializes ZSH integration in `~/.zshenv`
4. Links configuration files to `$XDG_CONFIG_HOME`
5. Installs **ubi** (Universal Binary Installer) for GitHub release management
6. Installs **yq** (TOML/YAML/JSON parser) for manifest parsing (minimal binary-only install)
7. Prompts to run platform-specific host provisioning

**Note:** The installer bootstraps `ubi` and a minimal `yq` binary as they are required dependencies for the app management system. For the full `yq` installation with man pages, run `dev app install yq` after bootstrap.

### Uninstall

Remove symlinks and restore any backed-up files:

```bash
cd ~/.local/share/dev
./uninstall.sh
```

## Quick Start

After installation, restart your shell or run:
```bash
source ~/.zshenv
```

Then you can use the `dev` command:

```bash
# Show all available commands
dev -h

# Check configuration status
dev config status

# Provision your host system
dev host

# Install a tool
dev tool rust install
```

## Commands

### Environment

Export environment configuration:
```bash
dev env
```

Outputs shell commands to set up XDG variables, DEV_HOME, and PATH. This is automatically evaluated during shell initialization.

### Shell Integration

Initialize ZSH integration (one-time setup):
```bash
dev init
```

Adds bootstrap code to `~/.zshenv` that loads the dev environment on shell startup.

### Configuration Management

Manage configuration file symlinks:
```bash
dev config status    # Show status of all configuration files
dev config link      # Link all configuration files
dev config unlink    # Unlink all configuration files
```

Configuration files live in `config/` and are symlinked to `$XDG_CONFIG_HOME/`.

### Host Provisioning

Run platform-specific provisioning:
```bash
dev host
```

Automatically detects your platform (macOS, Fedora, Ubuntu) and runs the appropriate provisioning script. These scripts are fully idempotent - they install missing packages and update existing ones in a single run.

**Platform Support:**
- **macOS** - Xcode tools, Homebrew, Brewfile packages, system settings
- **Fedora** - Firmware updates, rpm-ostree/dnf packages, Flatpak setup, desktop settings
- **Ubuntu/Debian** - APT packages, system updates

### Tool Management

Install and manage development tools:
```bash
dev tool                      # List available tools
dev tool <name>               # Show tool status
dev tool <name> install       # Install the tool
dev tool <name> update        # Update the tool
dev tool <name> uninstall     # Uninstall the tool
```

**Available Tools:**

*Language Toolchains:*
- `rust` - Rust via rustup
- `ruby` - Ruby via rbenv
- `go` - Go language toolchain
- `python` - Python via uv
- `nodejs` - Node.js via fnm

*Package Managers:*
- `homebrew` - Homebrew for macOS/Linux
- `flatpak` - Flatpak for Linux

*Applications:*
- `claude` - Claude Code CLI
- `tailscale` - Tailscale VPN client
- `zed` - Zed editor

*Utilities:*
- `ubi` - GitHub release binary installer

### Edit

Open the dev repository in your editor:
```bash
dev edit
```

Uses the `$EDITOR` environment variable.

### Script Runner

Run utility scripts from the `scripts/` directory:
```bash
dev script                    # List available scripts
dev script <name>             # Run a script
dev script <name> -- <args>   # Run a script with arguments
```

**Example:**
```bash
dev script gitconfig          # Configure git for this machine
dev script gpg-backup -- /path/to/backup
```

## Directory Structure

```
bin/                  Main dev tool and helper scripts
config/              Configuration files symlinked to $XDG_CONFIG_HOME
  ├── git/           Git configuration
  ├── zsh/           ZSH configuration with rc.d modules
  └── ...            Other application configs
hosts/               Platform-specific provisioning scripts
  ├── macos.sh       macOS provisioning
  ├── fedora.sh      Fedora provisioning
  └── ubuntu.sh      Ubuntu/Debian provisioning
tools/               Installable tools with install/update/uninstall actions
scripts/             Utility and configuration scripts
  ├── gpg.sh         GPG configuration
  ├── ssh.sh         SSH configuration
  └── ...            Other utility scripts
docs/                Documentation
```

## Configuration Override

User-specific configurations can be placed in `$XDG_CONFIG_HOME/dev/` to override defaults without modifying the main repository.

## Environment Variables

- `DEV_HOME` - Location of dev repository (default: `$HOME/.local/share/dev`)
- `DEV_CONFIG` - User config override directory (default: `$XDG_CONFIG_HOME/dev`)
- `TARGET` - Target directory for symlinks (default: `$HOME`)
- `XDG_CONFIG_HOME` - User configuration files (default: `$TARGET/.config`)
- `XDG_DATA_HOME` - User data files (default: `$TARGET/.local/share`)
- `XDG_BIN_HOME` - User executables (default: `$TARGET/.local/bin`)

**Testing Mode:**
You can test dev without affecting your home directory:
```bash
dev -t /tmp/test-home config link
```

All XDG paths are derived from TARGET to ensure consistency.

## Options

All commands support these options:

- `-d <dir>` - Dev directory (default: `$HOME/.local/share/dev`)
- `-t <dir>` - Target directory (default: `$HOME`)
- `-v` - Verbose output
- `-h` - Show help

## Scripts Directory

The `scripts/` directory contains utility scripts that are run via `dev script <name>`:

**Configuration:**
- `gitconfig` - Generate machine-specific git configuration
- `github` - GitHub CLI setup
- `gpg` - GPG configuration
- `ssh` - SSH configuration

**Backup/Restore:**
- `gpg-backup` - Backup GPG keys
- `gpg-restore` - Restore GPG keys

**Specialized:**
- `ssh-yk` - YubiKey SSH configuration
- `yubico` - YubiKey tools setup
- `tailnet` - Tailscale network setup
- `steam` - Steam gaming platform

Run these scripts using `dev script`:
```bash
dev script gitconfig
dev script gpg-backup -- /path/to/backup
```

## Design Philosophy

- **Shell Script Based** - POSIX-compliant `#!/bin/sh` for maximum compatibility
- **Idempotent** - All scripts can be run multiple times safely
- **Modular** - Tools and configurations can be managed independently
- **Portable** - Installs to `$XDG_DATA_HOME` or `$XDG_BIN_HOME` instead of system directories
- **Cross-Platform** - Supports macOS (primary), Fedora, and Ubuntu
- **ZSH Only** - Shell integration focused on ZSH

## Requirements

- **Shell**: ZSH (for shell integration)
- **OS**: macOS, Fedora, or Ubuntu/Debian
- **Tools**: git, curl, standard POSIX utilities

## License

Personal project - use at your own risk.

Licensed under the [MIT License](LICENSE).
