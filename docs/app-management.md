# Application Management System

The `dev app` command provides unified application management across different installer types and platforms using declarative manifest files.

## Dependencies

The app management system requires:
- **ubi** - Universal Binary Installer for GitHub releases (auto-installed during bootstrap)
- **yq** - TOML/YAML/JSON parser for manifest parsing (minimal version auto-installed during bootstrap)

Both are automatically installed by `install.sh` if not already present.

**Note:** The bootstrap installs a minimal `yq` binary to enable manifest parsing. For the full installation with man pages, run `dev app install yq` after bootstrap.

## Overview

Instead of managing each application individually, you define all your applications in a platform-specific TOML manifest file. The `dev app` command reads this manifest and uses the appropriate installer backend (DMG, UBI, Flatpak) to manage each application.

## Quick Start

```bash
# List all apps in the manifest
dev app list

# Install a specific app
dev app install ghostty

# Install all apps
dev app install --all

# Check status of all apps
dev app status --all

# Update a specific app
dev app update helix

# Uninstall an app
dev app uninstall ghostty
```

## Supported Installer Types

### DMG (macOS)
- **Use for:** macOS GUI applications distributed as DMG files
- **Features:** Code signature verification, quarantine removal, Launch Services registration
- **Platform:** macOS only

### UBI (Universal Binary Installer)
- **Use for:** CLI tools distributed via GitHub releases
- **Features:** Automatic architecture detection, symlink management, completions
- **Platform:** Cross-platform (macOS, Linux)
- **Parser:** Uses `yq` for robust TOML manifest parsing

### Flatpak (Linux)
- **Use for:** Linux GUI applications from Flathub
- **Features:** Sandboxed apps, automatic updates, desktop integration
- **Platform:** Linux only

## Manifest Files

Manifest files are located in `hosts/`:
- `hosts/cli.toml` - Shared CLI tools (cross-platform)
- `hosts/macos.toml` - macOS-specific applications (DMG installers)
- `hosts/linux.toml` - Linux-specific applications (Flatpak)

### Multi-Manifest Support

The system automatically loads multiple manifest files:
- **cli.toml** - Shared CLI tools installed via UBI (helix, yq, fd, ripgrep, etc.)
- **platform.toml** - Platform-specific apps (DMG for macOS, Flatpak for Linux)

Platform-specific manifests can override entries from `cli.toml` if needed.

### Platform Auto-Detection

By default, `dev app` automatically loads manifests based on your platform:
- macOS → `cli.toml` + `macos.toml`
- Linux → `cli.toml` + `linux.toml`

You can override this with `--file <path>` to use a custom manifest.

## Manifest Format

Each application is defined in a TOML section with an installer type and type-specific configuration.

**Note:** Manifests are parsed using `yq`, which provides full TOML spec support including:
- Multi-line strings
- Inline arrays (must be on a single line: `key = ["a", "b", "c"]`)
- Comments
- All TOML data types

### Manifest Organization

**cli.toml** - Cross-platform CLI tools:
```toml
[helix]
installer = "ubi"
project = "helix-editor/helix"
extract_all = true
symlinks = ["hx:${XDG_BIN_HOME}/hx", "contrib/completion/hx.zsh:${XDG_DATA_HOME}/zsh/completions/_hx"]
status_cmd = "hx --version"
```

**macos.toml** - macOS-specific apps:
```toml
[ghostty]
installer = "dmg"
url = "https://ghostty.org/download"
app = "Ghostty.app"
team_id = "24VZTF6M5V"
```

**linux.toml** - Linux-specific apps:
```toml
[flatseal]
installer = "flatpak"
app_id = "com.github.tchx84.Flatseal"
remote = "flathub"
```

### DMG Applications (macOS)

```toml
[ghostty]
installer = "dmg"
url = "https://ghostty.org/download"
app = "Ghostty.app"
team_id = "24VZTF6M5V"           # Optional: verify code signature
auto_update = true                # Optional: skip updates if app has built-in auto-update
user = false                      # Optional: install to ~/Applications instead of /Applications
install_dir = "/Applications"     # Optional: override install location
```

**Required fields:**
- `installer` - Must be "dmg"
- `url` - Download URL for the DMG file
- `app` - Application bundle name (e.g., "MyApp.app")

**Optional fields:**
- `team_id` - Apple Developer Team ID for signature verification
- `auto_update` - Set to `true` if app has built-in auto-update
- `user` - Set to `true` to install in `~/Applications`
- `install_dir` - Override default installation directory

### UBI Tools (Cross-platform)

Simple tool (binary only):
```toml
[fd]
installer = "ubi"
project = "sharkdp/fd"
# bin_name defaults to "fd" (section name)
# install_dir defaults to "${XDG_BIN_HOME}"
```

Complex tool (with runtime files):
```toml
[helix]
installer = "ubi"
project = "helix-editor/helix"
extract_all = true
# install_dir defaults to "${XDG_DATA_HOME}/helix" (uses section name)
symlinks = ["hx:${XDG_BIN_HOME}/hx", "contrib/completion/hx.zsh:${XDG_DATA_HOME}/zsh/completions/_hx"]
status_cmd = "hx --version"  # Binary name differs from section name
```

**Required fields:**
- `installer` - Must be "ubi"
- `project` - GitHub repository (owner/repo)

**Optional fields:**
- `bin_name` - Name of the binary (default: section name)
  - Only needed when `extract_all = false` and binary name differs from section name
  - When `extract_all = false`: Used by UBI to identify which binary to extract from archive
  - When `extract_all = true`: Not needed - symlinks auto-detect platform-specific binaries
- `extract_all` - Extract entire archive instead of just binary (default: `false`)
- `install_dir` - Installation directory (smart defaults apply, see below)
- `symlinks` - TOML array of "src:dest" pairs for creating symlinks
  - Supports auto-detection of platform-specific binaries (e.g., `yq_darwin_arm64`, `yq_linux_amd64`)
- `status_cmd` - Command to run for status checking (default: tries `<section_name> --version` then `<section_name> version`)

**Smart defaults:**
- `bin_name`: Defaults to the section name (e.g., `[fd]` → `bin_name = "fd"`)
  - Only specify when `extract_all = false` and binary name differs from section name
  - When `extract_all = true`, use `status_cmd` instead of `bin_name`
- `install_dir`:
  - If `extract_all = true`: Defaults to `${XDG_DATA_HOME}/<section_name>`
  - If `extract_all = false` or unset: Defaults to `${XDG_BIN_HOME}`
  - You can override by explicitly setting `install_dir`
- `status_cmd`: Defaults to trying `<section_name> --version` then `<section_name> version`
  - Specify when binary name differs from section name or uses non-standard version command
  - Set to empty string (`status_cmd = ""`) to skip version check
</parameter>

**Smart Binary Detection:**

When using `extract_all = true`, archives often contain platform-specific binaries (e.g., `yq_darwin_arm64`, `tool_linux_amd64`). The symlink system automatically detects these:

```toml
[yq]
installer = "ubi"
project = "mikefarah/yq"
extract_all = true
# Symlink "yq" auto-detects yq_darwin_arm64, yq_linux_amd64, etc.
symlinks = ["yq:${XDG_BIN_HOME}/yq", "yq.1:${XDG_DATA_HOME}/man/man1/yq.1"]
```

If the exact source file doesn't exist, the system looks for files matching `<name>_*` and uses the first match.

**Environment variables in paths:**
- `${XDG_BIN_HOME}` - User binaries (default: `~/.local/bin`)
- `${XDG_DATA_HOME}` - User data (default: `~/.local/share`)
- `${XDG_CONFIG_HOME}` - User config (default: `~/.config`)

### Flatpak Applications (Linux)

```toml
[vivaldi]
installer = "flatpak"
app_id = "com.vivaldi.Vivaldi"
remote = "flathub"
```

**Required fields:**
- `installer` - Must be "flatpak"
- `app_id` - Flatpak application ID

**Optional fields:**
- `remote` - Flatpak remote (default: "flathub")

## Commands

### install

Install one or more applications from the manifest.

```bash
# Install specific app
dev app install ghostty

# Install all apps
dev app install --all

# Use custom manifest
dev app install --file custom.toml --all
```

### uninstall

Remove installed applications.

```bash
# Uninstall specific app
dev app uninstall ghostty

# Uninstall all apps
dev app uninstall --all
```

### status

Check installation status and verify signatures.

```bash
# Check specific app
dev app status ghostty

# Check all apps
dev app status --all

# Use custom manifest
dev app status --file custom.toml --all
```

**Output for DMG apps includes:**
- Installation path
- Code signature information
- Team ID verification (if configured)

**Output for UBI tools includes:**
- Installation status (checks if install directory exists)
- Version information (runs status_cmd or tries default version commands)
</parameter>

**Output for Flatpak apps includes:**
- Installation status
- Version and branch information

### update

Update applications to the latest version.

```bash
# Update specific app
dev app update helix

# Update all apps
dev app update --all
```

**Note:** Apps with `auto_update = true` in the manifest will be skipped.

### list

List all applications defined in the manifest.

```bash
# List apps from auto-detected manifest
dev app list

# List apps from custom manifest
dev app list --file custom.toml
```

## Examples

### Example: macOS Setup

```toml
# hosts/cli.toml (shared across platforms)

[helix]
installer = "ubi"
project = "helix-editor/helix"
extract_all = true
symlinks = ["hx:${XDG_BIN_HOME}/hx", "contrib/completion/hx.zsh:${XDG_DATA_HOME}/zsh/completions/_hx"]
status_cmd = "hx --version"

[gh]
installer = "ubi"
project = "cli/cli"
extract_all = true
symlinks = ["bin/gh:${XDG_BIN_HOME}/gh"]

[fd]
installer = "ubi"
project = "sharkdp/fd"

[yq]
installer = "ubi"
project = "mikefarah/yq"
extract_all = true
# Auto-detects yq_darwin_arm64 on macOS, yq_linux_amd64 on Linux
symlinks = ["yq:${XDG_BIN_HOME}/yq", "yq.1:${XDG_DATA_HOME}/man/man1/yq.1"]
```

```toml
# hosts/macos.toml (macOS-specific)

[ghostty]
installer = "dmg"
url = "https://ghostty.org/download"
app = "Ghostty.app"
team_id = "24VZTF6M5V"
auto_update = true
```

```bash
# Install everything (loads cli.toml + macos.toml)
dev app install --all

# Check status
dev app status --all
```

### Example: Linux Setup

```toml
# hosts/cli.toml (shared, same as macOS)

[fd]
installer = "ubi"
project = "sharkdp/fd"

[ripgrep]
installer = "ubi"
project = "BurntSushi/ripgrep"
bin_name = "rg"

[yq]
installer = "ubi"
project = "mikefarah/yq"
extract_all = true
# Auto-detects yq_linux_amd64 on Linux, yq_darwin_arm64 on macOS
symlinks = ["yq:${XDG_BIN_HOME}/yq", "yq.1:${XDG_DATA_HOME}/man/man1/yq.1"]
```

```toml
# hosts/linux.toml (Linux-specific)

[vivaldi]
installer = "flatpak"
app_id = "com.vivaldi.Vivaldi"
remote = "flathub"

[flatseal]
installer = "flatpak"
app_id = "com.github.tchx84.Flatseal"
remote = "flathub"
```

```bash
# Install everything (loads cli.toml + linux.toml)
dev app install --all

# Update everything
dev app update --all
```

## Benefits of Multi-Manifest Design

1. **No Duplication** - CLI tools defined once in `cli.toml`
2. **Clear Separation** - Platform apps separated from cross-platform tools
3. **Easy Maintenance** - Update CLI tools in one place
4. **Override Support** - Platform manifests can override `cli.toml` entries
5. **Scalability** - Easy to add new platforms or tool categories

## Migration from Individual Tool Scripts

### Removed Tool Scripts

The following tool scripts have been removed as they are now managed by the manifest system:

- **`tools/helix.sh`** → Use `dev app install helix` (defined in `hosts/cli.toml`)
- **`tools/gh.sh`** → Use `dev app install gh` (defined in `hosts/cli.toml`)
- **`tools/codex.sh`** → Use `dev app install codex` (defined in `hosts/cli.toml`)
- **`tools/cosign.sh`** → Use `dev app install cosign` (defined in `hosts/cli.toml`)

All CLI tools installed via UBI are now declared in `hosts/cli.toml` and managed through the unified app system.

### Remaining Tool Scripts

The following tool scripts remain for special cases that require custom logic:

- **Language Toolchains**: `go.sh`, `nodejs.sh`, `python.sh`, `ruby.sh`, `rust.sh`
- **Platform Tools**: `homebrew.sh`, `flatpak.sh`, `ubi.sh` (bootstrap)
- **Special Applications**: `claude.sh`, `zed.sh`, `tailscale.sh`

These tools have complex setup requirements, multiple installation methods, or platform-specific configurations that go beyond simple binary installation.

### Migration Commands

**Before:**
```bash
dev tool helix install
dev tool gh install
```

**After:**
```bash
dev app install helix
dev app install gh
```

### Benefits of the New System

1. **Single Source of Truth** - All CLI apps defined in one manifest file
2. **Platform-Aware** - Cross-platform tools in `cli.toml`, platform apps in `macos.toml`/`linux.toml`
3. **Batch Operations** - Install/update all apps at once with `--all`
4. **Declarative** - Define desired state, not installation steps
5. **Consistent Interface** - Same commands for all installer types (DMG, UBI, Flatpak)
6. **Less Code** - Individual tool scripts replaced by manifest entries
7. **Smart Defaults** - Auto-detection of platform-specific binaries

## Architecture

The app management system is modular:

```
lib/
├── app.sh              # Main app subcommand logic
├── toml.sh             # TOML parsing utilities
└── app/
    ├── dmg.sh          # DMG installer backend
    ├── ubi.sh          # UBI installer backend
    └── flatpak.sh      # Flatpak installer backend
```

Each installer backend is self-contained and can be tested independently.

## Troubleshooting

### DMG Installation Issues

**Problem:** Team ID verification fails
```
team id mismatch       Expected: ABC123, Found: XYZ789
```

**Solution:** Update the `team_id` in the manifest or remove it to skip verification.

**Problem:** Permission denied when installing to /Applications
```
app not found          /Applications/MyApp.app
```

**Solution:** Either run with sudo, add `user = true` to install in ~/Applications, or check file permissions.

### UBI Installation Issues

**Problem:** ubi not found
```
ubi not installed      Install ubi first: dev tool ubi install
```

**Solution:** Install ubi first: `dev tool ubi install`

**Problem:** Binary not found after installation
```
tool.mytool            not installed
```

**Solution:** Ensure `${XDG_BIN_HOME}` is in your PATH, or check the symlinks configuration.

### Flatpak Installation Issues

**Problem:** Flatpak not available
```
flatpak unavailable    Flatpak is not installed on this system
```

**Solution:** Install Flatpak using your system package manager.

**Problem:** Remote not found
```
unknown remote         custom-remote
```

**Solution:** Add the remote manually or use a supported remote (flathub, fedora).

## Advanced Usage

### Custom Manifest Files

Create custom manifests for different scenarios:

```bash
# Work tools
dev app install --file work-tools.toml --all

# Personal apps
dev app install --file personal.toml --all
```

### Symlink Management (UBI)

UBI tools support creating symlinks for binaries and completions using TOML arrays with automatic platform-specific binary detection:

```toml
[mytool]
installer = "ubi"
project = "owner/repo"
extract_all = true
# install_dir defaults to ${XDG_DATA_HOME}/mytool when extract_all = true
symlinks = [
  "mytool:${XDG_BIN_HOME}/mytool",  # Auto-detects mytool_darwin_arm64, mytool_linux_amd64, etc.
  "completions/_mytool:${XDG_DATA_HOME}/zsh/completions/_mytool"
]
```

**Format:** TOML array of `"source:destination"` pairs.

**Smart Detection:** If the exact source file doesn't exist, the system automatically looks for platform-specific variants like `tool_darwin_arm64` or `tool_linux_amd64`.

### Extract All vs. Binary Only (UBI)

- `extract_all = false` (default) - Extracts only the binary, installs to `${XDG_BIN_HOME}`
- `extract_all = true` - Extracts entire archive, installs to `${XDG_DATA_HOME}/<section_name>`

```toml
[helix]
installer = "ubi"
project = "helix-editor/helix"
extract_all = true       # Needed for runtime files and grammars
symlinks = ["hx:${XDG_BIN_HOME}/hx", "contrib/completion/hx.zsh:${XDG_DATA_HOME}/zsh/completions/_hx"]
status_cmd = "hx --version"  # Binary name differs from section name
# Automatically installs to ${XDG_DATA_HOME}/helix (uses section name)
# Symlink "hx" auto-detects platform-specific binary if needed
```

The smart defaults mean you rarely need to specify `install_dir` manually. Symlinks automatically detect platform-specific binaries when using `extract_all = true`.

### Status Checking (UBI)

The `status_cmd` field allows flexible status checking:

**Default behavior** (no `status_cmd` specified):
- First checks if install directory exists
- Then tries `<bin_name> --version`
- Falls back to `<bin_name> version`

**Custom status command:**
```toml
[mytool]
installer = "ubi"
project = "owner/mytool"
status_cmd = "mytool -v"  # Non-standard version flag
```

**When binary name differs from section name (extract_all = true):**
```toml
[helix]
installer = "ubi"
project = "helix-editor/helix"
extract_all = true
status_cmd = "hx --version"  # Binary name differs from section name
```

**When binary name differs from section name (extract_all = false):**
```toml
[ripgrep]
installer = "ubi"
project = "BurntSushi/ripgrep"
bin_name = "rg"  # UBI uses this to extract the correct binary
```

**Platform-specific binaries with extract_all:**
```toml
[yq]
installer = "ubi"
project = "mikefarah/yq"
extract_all = true
# Symlink auto-detects yq_darwin_arm64 on macOS, yq_linux_amd64 on Linux
symlinks = ["yq:${XDG_BIN_HOME}/yq", "yq.1:${XDG_DATA_HOME}/man/man1/yq.1"]
```


**Skip version check:**
```toml
[notool]
installer = "ubi"
project = "owner/notool"
status_cmd = ""  # Only checks if install directory exists
```
</parameter>

## See Also

- [TOML Specification](https://toml.io/)
- [yq Documentation](https://github.com/mikefarah/yq/) - TOML/YAML/JSON processor
- [UBI Documentation](https://github.com/houseabsolute/ubi) - Universal Binary Installer
- [Flatpak Documentation](https://docs.flatpak.org/) - Linux application sandboxing