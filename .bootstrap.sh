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
if ! grep -q "experimental-features = nix-command flakes" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
fi

# Deploy environment
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Updating macOS configuration..."
    
    if ! command -v darwin-rebuild >/dev/null 2>&1; then
        nix run nix-darwin -- switch --flake ~/.config/nix#default --argstr username "$USER"
    else
        darwin-rebuild switch --flake ~/.config/nix#default --argstr username "$USER"
    fi
    
    echo "🏠 Updating user environment..."
    
    # Create temporary flake for home-manager with current user
    TEMP_FLAKE=$(mktemp -d)
    cat > "$TEMP_FLAKE/flake.nix" << EOF
{
  inputs.config.url = "path:$HOME/.config/nix";
  outputs = { self, config }: {
    homeConfigurations.default = config.lib.mkHomeConfig "$USER" "aarch64-darwin";
  };
}
EOF
    
    if ! command -v home-manager >/dev/null 2>&1; then
        nix run home-manager/master -- switch --flake "$TEMP_FLAKE#default"
    else
        home-manager switch --flake "$TEMP_FLAKE#default"
    fi
    
    rm -rf "$TEMP_FLAKE"
else
    echo "🐧 Updating Linux environment..."
    # Detect ARM vs x86
    if [[ $(uname -m) == "aarch64" ]]; then
        FLAKE_CONFIG="linux-aarch64"
    else
        FLAKE_CONFIG="linux-x86_64"
    fi
    
    # Determine system architecture for home-manager
    if [[ $(uname -m) == "aarch64" ]]; then
        HM_SYSTEM="aarch64-linux"
    else
        HM_SYSTEM="x86_64-linux"
    fi
    
    # Create temporary flake for home-manager with current user
    TEMP_FLAKE=$(mktemp -d)
    cat > "$TEMP_FLAKE/flake.nix" << EOF
{
  inputs.config.url = "path:$HOME/.config/nix";
  outputs = { self, config }: {
    homeConfigurations.default = config.lib.mkHomeConfig "$USER" "$HM_SYSTEM";
  };
}
EOF
    
    if ! command -v home-manager >/dev/null 2>&1; then
        nix run home-manager/master -- switch --flake "$TEMP_FLAKE#default"
    else
        home-manager switch --flake "$TEMP_FLAKE#default"
    fi
    
    rm -rf "$TEMP_FLAKE"
fi

# Set fish as default shell
echo "🐟 Setting up fish as default shell..."
FISH_PATH=$(command -v fish)
if [ -n "$FISH_PATH" ]; then
    # Add fish to valid shells if not already present
    if ! grep -Fxq "$FISH_PATH" /etc/shells 2>/dev/null; then
        echo "Adding fish to /etc/shells..."
        echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    
    # Change default shell to fish
    if [ "$SHELL" != "$FISH_PATH" ]; then
        echo "Changing default shell to fish..."
        chsh -s "$FISH_PATH"
        echo "✅ Default shell changed to fish"
    else
        echo "✅ Fish is already the default shell"
    fi
else
    echo "⚠️  Fish not found, skipping shell change"
fi

echo "🎉 Bootstrap complete! Restart your terminal to use the new environment."
