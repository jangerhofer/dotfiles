# dotfiles

Personal dotfiles managed with a bare Git repository.

## Quick Setup

### Automated Setup (Recommended)

```bash
# Clone dotfiles as bare repository
git clone --bare https://github.com/jangerhofer/dotfiles.git $HOME/.dotfiles

# Create alias for managing dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Backup any existing conflicting files
mkdir -p ~/.config-backup
dotfiles checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} ~/.config-backup/{} 2>/dev/null || true

# Checkout dotfiles
dotfiles checkout
dotfiles config --local status.showUntrackedFiles no

# Run automated bootstrap (installs Nix, applies configurations, sets Nushell as default)
./.bootstrap.sh
```

### Manual Setup (macOS with Homebrew)

For those preferring manual control:

```bash
# Install Homebrew first
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Follow automated setup steps above, then:
brew bundle --file ~/.Brewfile
```

*Note: Restart your terminal after bootstrap completes so your default Nushell environment is active. After bootstrap, use `dt` for dotfiles operations.*

## Usage

### Basic Operations
```bash
# Check status (only shows tracked files)
dt status

# Add new files to track
dt add .vimrc
dt add .config/tmux/

# Commit changes
dt commit -m "Update vim config"

# Push changes
dt push
```

### Advanced Operations
```bash
# Remove file from tracking (keeps local file)
dt rm --cached .unwanted-file

# Stop tracking a directory
dt rm -r --cached .config/unwanted/

# View tracked files
dt ls-files

# Diff changes
dt diff

# View history
dt log --oneline
```

## How It Works

This setup uses a bare Git repository stored in `~/.dotfiles/` to track configuration files throughout your home directory. Files stay in their natural locations (`.vimrc` in `~`, `.config/` in `~/.config/`) while Git metadata is kept separate.

Based on [Atlassian's bare repository guide](https://www.atlassian.com/git/tutorials/dotfiles).

## Nix Configuration

The dotfiles include a comprehensive Nix setup located in `~/.config/nix/` that provides cross-platform development environment management for both macOS and Linux.

### Structure

```
~/.config/nix/
├── flake.nix          # Main Nix flake configuration
├── flake.lock         # Pinned dependency versions
├── nix.conf           # Nix daemon configuration
├── modules/           # Modular configurations
│   ├── home.nix       # Main Home Manager config
│   ├── nushell.nix    # Nushell configuration
│   ├── git.nix        # Git configuration
│   ├── helix.nix      # Helix editor configuration
│   ├── lazygit.nix    # Lazygit configuration
│   ├── starship.nix   # Starship prompt configuration
│   ├── btop.nix       # System monitor configuration
│   ├── ghostty.nix    # Terminal emulator configuration
│   ├── k9s.nix        # Kubernetes CLI configuration
│   ├── cloud.nix      # Cloud and infrastructure tooling
│   ├── fonts.nix      # Font packages
│   ├── media-server.nix # Optional media server profile
│   └── ssh.nix        # SSH configuration
└── configs/           # Application configuration files
    ├── helix/         # Helix editor themes
    └── k9s/           # K9s skins and config
```

### Features

- **Cross-platform**: Supports both macOS (via nix-darwin) and Linux
- **Modular design**: Each application has its own Nix module for easy management
- **System integration**: On macOS, manages system preferences via nix-darwin
- **Development tools**: Includes modern CLI tools like ripgrep, lazygit, zellij, btop
- **Reproducible**: Flake.lock ensures consistent dependency versions

### Nix Management Commands

```bash
# Update flake inputs
nix flake update ~/.config/nix

# Apply changes to system configuration (macOS only)
darwin-rebuild switch --flake ~/.config/nix#default

# Apply changes to Home Manager configuration
# Use the appropriate configuration for your system:
# - macos-aarch64: macOS Apple Silicon
# - linux-x86_64: Linux Intel/AMD  
# - linux-aarch64: Linux ARM64
home-manager switch --flake ~/.config/nix#macos-aarch64

# Check configuration without applying
nix flake check ~/.config/nix

# Show what packages would be activated
nix build ~/.config/nix#homeConfigurations.macos-aarch64.activationPackage --dry-run

# Garbage collect old generations
nix-collect-garbage -d
```

### Managed Applications

The Nix configuration manages:

- **Shell**: Nushell with custom functions and completions
- **Editor**: Helix with language server configurations  
- **Terminal**: Ghostty terminal emulator settings
- **Development**: Git, SSH, starship prompt, development tools
- **Monitoring**: btop system monitor, k9s Kubernetes interface
- **System**: macOS preferences and settings (via nix-darwin)

### Why Home Manager Downloads Large Amounts of Data

When running `hm` (home-manager switch), you might see large downloads (100+ MB) even without updating your flake. This happens because:

1. **Recently updated pins may outrun binary caches**: Even on stable inputs, very fresh package revisions or less common packages may not have binaries cached yet. If you run `hm` before binaries are available, Nix must download:
   - Source code
   - Build dependencies (compilers, build tools)
   - Transitive dependencies
   
2. **Example**: Building a 1MB program might download:
   - Source: 1MB
   - GCC compiler: 150MB
   - Development headers: 20MB
   - Build tools: 10MB
   - Total: ~180MB to build a 1MB binary

#### Solutions

1. **Stay on stable inputs unless you need newer packages**: The current flake already uses a stable `nixpkgs` release:
   ```nix
   nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
   ```
   Stable releases usually have better binary cache coverage.

2. **Wait after updates**: After running `nup` (nix flake update), wait a day before running `hm` to give the build farm time to cache binaries.

3. **Use community caches**: Add cachix or other binary caches that might have pre-built unstable packages.

#### How Pinning Works

- `flake.nix`: Points to a branch or release (e.g., `nixos-25.05`)
- `flake.lock`: Pins to specific commit
- `nup`: Updates the pin in `flake.lock`
- `hm`: Uses the pinned commit

Downloads occur not from updating nixpkgs, but from building packages that lack cached binaries at your pinned commit.
