#!/bin/bash
set -euo pipefail

echo "🚀 Starting environment bootstrap with Nix..."

backup_etc_file() {
    local target="$1"
    local backup="${target}.before-nix-darwin"
    if [ -e "$target" ] && [ ! -L "$target" ] && [ ! -e "$backup" ]; then
        echo "📁 Backing up $target to ${backup} so nix-darwin can manage it..."
        sudo mv "$target" "$backup"
    fi
}

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
    backup_etc_file "/etc/shells"
    
    # Use direct flake configuration
    if ! command -v darwin-rebuild >/dev/null 2>&1; then
        sudo nix run nix-darwin -- switch --flake ~/.config/nix#default
    else
        sudo darwin-rebuild switch --flake ~/.config/nix#default
    fi
    
    echo "🏠 Updating user environment..."
    
    # Use direct flake configuration
    if ! command -v home-manager >/dev/null 2>&1; then
        nix run home-manager/master -- switch --flake ~/.config/nix#macos-aarch64
    else
        home-manager switch --flake ~/.config/nix#macos-aarch64
    fi
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

# Set Nushell as default shell
echo "🌀 Setting up Nushell as default shell..."
# Prefer the system-managed Nu path (matches /etc/shells), fall back to PATH lookup
if [ -x /run/current-system/sw/bin/nu ]; then
    NU_PATH=/run/current-system/sw/bin/nu
else
    NU_PATH=$(command -v nu || true)
fi
if [ -n "$NU_PATH" ]; then
    can_switch_shell=true
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! grep -Fxq "$NU_PATH" /etc/shells 2>/dev/null; then
            echo "⚠️  Nushell isn't listed in /etc/shells yet. Run the darwin switch first, then rerun this script to change your shell."
            can_switch_shell=false
        fi
    else
        if ! grep -Fxq "$NU_PATH" /etc/shells 2>/dev/null; then
            echo "Adding Nushell to /etc/shells..."
            echo "$NU_PATH" | sudo tee -a /etc/shells >/dev/null
        fi
    fi
    
    if [ "$can_switch_shell" = true ]; then
        # Get current user's shell
        CURRENT_SHELL=$(dscl . -read /Users/$USER UserShell 2>/dev/null | awk '{print $2}' || echo "$SHELL")
        
        # Change default shell to Nushell
        if [ "$CURRENT_SHELL" != "$NU_PATH" ]; then
            echo "Changing default shell to Nushell..."
            echo "Current shell: $CURRENT_SHELL"
            echo "Target shell: $NU_PATH"
            
            # Try chsh first
            if sudo chsh -s "$NU_PATH" "$USER" 2>/dev/null; then
                echo "✅ Default shell changed to Nushell"
            # If chsh fails, try dscl on macOS
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                if sudo dscl . -change /Users/$USER UserShell "$CURRENT_SHELL" "$NU_PATH" 2>/dev/null; then
                    echo "✅ Default shell changed to Nushell (via dscl)"
                else
                    echo "⚠️  Could not change default shell automatically. Run manually:"
                    echo "    sudo chsh -s $NU_PATH $USER"
                    echo "    or: sudo dscl . -change /Users/$USER UserShell $CURRENT_SHELL $NU_PATH"
                fi
            else
                echo "⚠️  Could not change default shell automatically. Run manually:"
                echo "    sudo chsh -s $NU_PATH $USER"
                echo "    or: sudo dscl . -change /Users/$USER UserShell $CURRENT_SHELL $NU_PATH"
            fi
        else
            echo "✅ Nushell is already the default shell"
        fi
    fi
else
    echo "⚠️  Nushell not found, skipping shell change"
fi

echo "🎉 Bootstrap complete! Restart your terminal to use the new environment."
