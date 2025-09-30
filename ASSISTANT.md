# ASSISTANT.md

This file provides guidance to AI assistants when working with code in this repository.

## Repository Overview

This is a personal developer environment management system called `dev` that manages configuration files, provisioning scripts, and development tools across macOS and Linux platforms. It uses symlinks to manage configurations and includes idempotent provisioning scripts for setting up development environments.

The project is an opinionated setup that reflects personal preferences and workflow. It's designed to take a new machine or VM and quickly set it up for development with minimal manual intervention. The system is agnostic about package managers and uses tools directly whenever possible for consistency across platforms.

The project is organized around XDG Base Directory Specification and installs tools portably into `$XDG_DATA_HOME` or `$XDG_BIN_HOME` rather than system directories.

## Background

This project is based on a previous dotfiles management system ([ascarter/dotfiles](https://github.com/ascarter/dotfiles)) but has been significantly expanded. The original project was primarily focused on managing dotfiles, but this new project expands the scope to include provisioning scripts and other tools with more comprehensive and flexible provisioning capabilities.

The original dotfiles project was entirely shell script based. This project continues with that approach for now due to the ease of reading and modifying shell scripts, though it may be reconsidered in the future if the project becomes more complex (potential alternatives: Rust or Go).

## Architecture

The system is built around a central `bin/dev` tool that will manage the developer environment. Configuration files are symlinked from `config/` to appropriate locations, and provisioning is handled through platform-specific scripts in `hosts/` and tool-specific scripts in `tools/`.

**Key Design Principles:**
- Shell script-based (POSIX-compliant `#!/bin/sh`)
- All scripts are idempotent and can be run multiple times safely
- Modular and extensible - tools can be installed independently
- Avoids system pollution by using portable installations
- Cross-platform support for macOS (primary), Linux (usually Fedora), and Windows (WSL or native)
- **zsh only** - Shell integration and init focused on zsh

## Directory Structure

- `bin/` - Main `dev` tool and helper scripts (can be scripts)
- `config/` - Configuration files symlinked to `$XDG_CONFIG_HOME` or specific target directories
- `hosts/` - Platform-specific provisioning (macos, fedora, ubuntu)
- `tools/` - Idempotent tool installation scripts for development tools, languages, frameworks, and applications
- `docs/` - Documentation

## Installation

The installation process is designed to be as simple as possible. The `install.sh` script bootstraps the setup by cloning the repository and linking the configuration files. It also sets up the necessary environment variables and initializes the shell integration.

```bash
./install.sh              # Fresh install (clones repo and links configs)
./install.sh -b <branch>  # Install with specific branch
./uninstall.sh            # Uninstall (removes symlinks, restores backups)
```

Tools are designed to be run independently and can be executed multiple times without causing issues. This allows for easy updates and modifications to the setup. Tools are not generally automatically installed - the user can install tools as needed and there will be conveniences for installing sets of tools (including all the tools).

## Commands

```bash
# Export environment configuration
dev env

# Initialize shell integration (zsh only)
dev init

# Update dev from git and re-link
dev update

# Edit dev repository in $EDITOR
dev edit

# Configuration file management
dev config status      # Show status of all configuration files
dev config link        # Link all configuration files
dev config unlink      # Unlink all configuration files

# Run host provisioning
dev host [platform]

# Manage tools
dev tool [name] [action]
```

## Key Environment Variables

- `DEV_HOME` - Location of dev repository (default: `$HOME/.local/share/dev`, can be overridden with `-d`)
- `DEV_CONFIG` - User config override directory (default: `$XDG_CONFIG_HOME/dev`)
- `TARGET` - Target directory for symlinks (default: `$HOME`, can be overridden with `-t`)
- `XDG_CONFIG_HOME` - Derived from TARGET: `$TARGET/.config`
- `XDG_DATA_HOME` - Derived from TARGET: `$TARGET/.local/share`
- `XDG_BIN_HOME` - Derived from TARGET: `$TARGET/.local/bin`

**Note:** When `-t` is specified, all XDG paths are derived from TARGET to ensure consistency. This allows safe testing without affecting your home directory.

## Configuration Override

User-specific configurations can be placed in `$XDG_CONFIG_HOME/dev/` to override defaults without modifying the main repository.

## Coding Standards

- DRY but within reason - implementing DRY principles should not lead to overly complex or unreadable code
- Prefer simple patterns of repeated code across scripts over complex inclusion of shared code or configuration
- Don't create functions that are called only once
- POSIX-compliant shell syntax (`#!/bin/sh`)
- Scripts must be idempotent
- No emojis or excessive colors in output
- Prefer bold/italic over colors

## Project Rules

- Standardize logging to match consistent logging form
- Honor .editorconfig guidelines
- Use XDG environment variables
- NEVER hardcode anything that could be a secret or identifiable (like names or logins)
- Use .editorconfig settings instead of modelines in the files
- Do not create git commits unless instructed to do so

## Hosts and Tools System

The `hosts/` directory will contain platform-specific provisioning scripts for macOS, Fedora, and Ubuntu. These scripts set up the base environment for each platform. *(Not yet implemented)*

The `tools/` directory will contain idempotent provisioning scripts for:
- Development tools
- Languages and frameworks
- Applications

All scripts can be run independently and repeatedly without issues. *(Not yet implemented)*

## Implementation Status

**Completed:**
- ✅ `bin/dev` - Main command with full option parsing and help
- ✅ `dev env` - Environment export for shell integration
- ✅ `dev config` - Complete symlink management (status/link/unlink)
- ✅ `config/` - All configuration files ported from dotfiles

**To Do:**
- ⏳ `dev init` - Shell initialization (zsh)
- ⏳ `dev update` - Git update and re-link
- ⏳ `dev edit` - Open repository in editor
- ⏳ `dev host` - Platform provisioning
- ⏳ `dev tool` - Tool installation management
- ⏳ `install.sh` and `uninstall.sh` - Bootstrap scripts

## Code Patterns

**Function Naming:**
- `cmd_*` - Command handlers (e.g., `cmd_config`, `cmd_env`)
- `*_usage` - Usage/help functions (e.g., `config_usage`, `usage_options`)
- `*_sync` or descriptive names - Helper functions (e.g., `config_sync`, `setup_environment`)

**Error Handling:**
- Invalid commands: Show error then usage
- Invalid subcommand actions: Show error then subcommand usage
- Pattern: "command: error message"

**Usage Display:**
- Shows expanded path values, not just variable names
- Subcommands show full command path (e.g., "dev config")
- Reusable `usage_options()` for DRY
- Options show actual current values (respects `-d` and `-t` overrides)
