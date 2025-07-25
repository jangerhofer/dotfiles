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

# Run automated bootstrap (installs Nix, applies configurations, sets fish as default)
./.bootstrap.sh
```

### Manual Setup (macOS with Homebrew)

For those preferring manual control:

```bash
# Install Homebrew first
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Follow automated setup steps above, then:
brew_restore  # Restore Homebrew packages
```

*Note: Restart your terminal after setting fish as the default shell. Fish config includes the `dotfiles` alias automatically after setup.*

## Usage

### Basic Operations
```bash
# Check status (only shows tracked files)
dotfiles status

# Add new files to track
dotfiles add .vimrc
dotfiles add .config/tmux/

# Commit changes
dotfiles commit -m "Update vim config"

# Push changes
dotfiles push
```

### Advanced Operations
```bash
# Remove file from tracking (keeps local file)
dotfiles rm --cached .unwanted-file

# Stop tracking a directory
dotfiles rm -r --cached .config/unwanted/

# View tracked files
dotfiles ls-files

# Diff changes
dotfiles diff

# View history
dotfiles log --oneline
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
│   ├── fish.nix       # Fish shell configuration
│   ├── git.nix        # Git configuration
│   ├── helix.nix      # Helix editor configuration
│   ├── nvim.nix       # Neovim configuration
│   ├── starship.nix   # Starship prompt configuration
│   ├── btop.nix       # System monitor configuration
│   ├── ghostty.nix    # Terminal emulator configuration
│   ├── k9s.nix        # Kubernetes CLI configuration
│   └── ssh.nix        # SSH configuration
└── configs/           # Application configuration files
    ├── fish/          # Fish shell functions and completions
    ├── helix/         # Helix editor themes
    ├── k9s/           # K9s skins and config
    └── nvim/          # Neovim Lua configurations
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
darwin-rebuild switch --flake ~/.config/nix#jdangerhofer-mac

# Apply changes to Home Manager configuration
# Use the appropriate configuration for your system:
# - macos-aarch64: macOS Apple Silicon
# - linux-x86_64: Linux Intel/AMD  
# - linux-aarch64: Linux ARM64
home-manager switch --flake ~/.config/nix#macos-aarch64

# Check configuration without applying
nix flake check ~/.config/nix

# Show what packages would be installed/removed
nix run home-manager/master -- switch --flake ~/.config/nix#macos-aarch64 --dry-run

# Garbage collect old generations
nix-collect-garbage -d
```

### Managed Applications

The Nix configuration manages:

- **Shell**: Fish with custom functions and completions
- **Editor**: Helix and Neovim with language server configurations  
- **Terminal**: Ghostty terminal emulator settings
- **Development**: Git, SSH, starship prompt, development tools
- **Monitoring**: btop system monitor, k9s Kubernetes interface
- **System**: macOS preferences and settings (via nix-darwin)

### Why Home Manager Downloads Large Amounts of Data

When running `hm` (home-manager switch), you might see large downloads (100+ MB) even without updating your flake. This happens because:

1. **Unstable channel lacks binary caches**: Using `nixpkgs-unstable` means you're on the bleeding edge. When packages update, the Nix build farm needs time to compile and cache binaries. If you run `hm` before binaries are cached, Nix must download:
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

1. **Switch to stable channel**: Change `nixpkgs.url` in `flake.nix` to:
   ```nix
   nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
   ```
   Stable releases have pre-built binaries available.

2. **Wait after updates**: After running `nup` (nix flake update), wait a day before running `hm` to give the build farm time to cache binaries.

3. **Use community caches**: Add cachix or other binary caches that might have pre-built unstable packages.

#### How Pinning Works

- `flake.nix`: Points to a branch (e.g., `nixos-unstable`)
- `flake.lock`: Pins to specific commit
- `nup`: Updates the pin in `flake.lock`
- `hm`: Uses the pinned commit

Downloads occur not from updating nixpkgs, but from building packages that lack cached binaries at your pinned commit.
