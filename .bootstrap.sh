#!/bin/bash
set -euo pipefail

echo "🚀 Starting environment bootstrap with Nix..."

# Detect operating system
OS="$(uname -s)"
case "${OS}" in
    Darwin*)    IS_MAC=true;;
    *)          IS_MAC=false;;
esac

# Check if Nix is installed
if ! command -v nix >/dev/null 2>&1; then
    echo "📦 Installing Nix package manager..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    
    # Source Nix environment
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
else
    echo "✅ Nix already installed"
fi

# Enable flakes (required for modern Nix)
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Deploy environment using Nix
if [ "$IS_MAC" = true ]; then
    echo "🍎 Setting up macOS environment with nix-darwin..."
    
    # Install nix-darwin if not already installed
    if ! command -v darwin-rebuild >/dev/null 2>&1; then
        echo "📦 Installing nix-darwin..."
        nix run nix-darwin -- switch --flake ~/.config/nix#jdangerhofer-mac
    else
        echo "🔄 Updating macOS configuration..."
        darwin-rebuild switch --flake ~/.config/nix#jdangerhofer-mac
    fi
    
    # Apply macOS preferences
    echo "⚙️  Applying macOS preferences..."
    defaults write "Apple Global Domain" com.apple.sound.uiaudio.enabled -int 0
    defaults write NSGlobalDomain _HIHideMenuBar -bool true
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write com.apple.dock autohide -int 1
    defaults write "com.apple.menuextra.clock" ShowSeconds -int 1
    defaults write "Apple Global Domain" AppleShowAllExtensions -int 1
    defaults write com.apple.Finder AppleShowAllFiles true
    defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
    mkdir -p $HOME/Desktop/Screenshots
    defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"
    defaults write -globalDomain AppleInterfaceStyle "Dark"
    
    killall Dock 2>/dev/null || true
    killall Finder 2>/dev/null || true
    killall SystemUIServer 2>/dev/null || true
else
    echo "🐧 Setting up Linux environment with Home Manager..."
    
    # Install Home Manager if not already installed
    if ! command -v home-manager >/dev/null 2>&1; then
        echo "📦 Installing Home Manager..."
        nix run home-manager/master -- switch --flake ~/.config/nix#jdangerhofer
    else
        echo "🔄 Updating Linux configuration..."
        home-manager switch --flake ~/.config/nix#jdangerhofer
    fi
fi

# Setup fish as default shell
echo "🐟 Setting up fish shell..."
FISH_PATH="$(which fish)"

if [ -n "$FISH_PATH" ]; then
    # Add fish to /etc/shells if it's not already there
    if ! grep -Fxq "$FISH_PATH" /etc/shells; then
        echo "Adding fish to /etc/shells"
        echo "$FISH_PATH" | sudo tee -a /etc/shells
    fi
    
    # Change the default shell for the current user
    if [ "$SHELL" != "$FISH_PATH" ]; then
        echo "Changing default shell to fish"
        chsh -s "$FISH_PATH"
    fi
else
    echo "⚠️  Fish not found in PATH. Home Manager should have installed it."
    echo "You may need to restart your terminal or run: source ~/.nix-profile/etc/profile.d/nix.sh"
fi

echo ""
echo "🎉 Bootstrap complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Restart your terminal or run: exec fish"
echo "  2. Your environment is now managed by Nix"
echo "  3. To update: ./bootstrap.sh (run again)"
echo "  4. To modify: edit ~/.config/nix/flake.nix and ~/.config/nix/home.nix"
