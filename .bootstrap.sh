#!/bin/bash
set -euo pipefail

echo "🚀 Starting environment bootstrap with Nix..."

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

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Deploy environment
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Updating macOS configuration..."
    if ! command -v darwin-rebuild >/dev/null 2>&1; then
        nix run nix-darwin -- switch --flake ~/.config/nix#jdangerhofer-mac
    else
        darwin-rebuild switch --flake ~/.config/nix#jdangerhofer-mac
    fi
    
    echo "🏠 Updating user environment..."
    if ! command -v home-manager >/dev/null 2>&1; then
        nix run home-manager/master -- switch --flake ~/.config/nix#jdangerhofer-mac
    else
        home-manager switch --flake ~/.config/nix#jdangerhofer-mac
    fi
else
    echo "🐧 Updating Linux environment..."
    if ! command -v home-manager >/dev/null 2>&1; then
        nix run home-manager/master -- switch --flake ~/.config/nix#jdangerhofer
    else
        home-manager switch --flake ~/.config/nix#jdangerhofer
    fi
fi

echo "🎉 Bootstrap complete! Restart your terminal to use the new environment."
