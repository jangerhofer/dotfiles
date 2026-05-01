#!/bin/bash
set -euo pipefail

echo "🚀 Starting environment bootstrap with Nix..."

EXPECTED_DARWIN_USER="jdangerhofer"

backup_etc_file() {
    local target="$1"
    local backup="${target}.before-nix-darwin"
    if [ -e "$target" ] && [ ! -L "$target" ] && [ ! -e "$backup" ]; then
        echo "📁 Backing up $target to ${backup} so nix-darwin can manage it..."
        sudo mv "$target" "$backup"
    fi
}

activate_home_manager_flake() {
    local flake_ref="$1"
    local temp_dir
    local out_link

    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' RETURN
    out_link="$temp_dir/home-manager"

    nix build "${flake_ref}.activationPackage" --out-link "$out_link"
    bash "$out_link/activate"
}

current_user() {
    id -un
}

run_as_root() {
    sudo env HOME=/var/root NIX_CONFIG="experimental-features = nix-command flakes" "$@"
}

check_darwin_user() {
    local user
    local expected_home

    user=$(current_user)
    expected_home="/Users/${EXPECTED_DARWIN_USER}"

    if [ "$user" != "$EXPECTED_DARWIN_USER" ]; then
        echo "❌ This macOS flake is configured for user '${EXPECTED_DARWIN_USER}', but you are logged in as '${user}'."
        echo "   Rename the macOS account and home folder first, then open a new terminal and rerun this script."
        echo "   Expected home directory: ${expected_home}"
        exit 1
    fi

    if [ "$HOME" != "$expected_home" ]; then
        echo "❌ HOME is '${HOME}', but this bootstrap expects '${expected_home}'."
        echo "   Open a fresh login shell after renaming the account, then rerun this script."
        exit 1
    fi
}

resolve_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        command -v brew
        return 0
    fi

    if [ -x /opt/homebrew/bin/brew ]; then
        echo /opt/homebrew/bin/brew
        return 0
    fi

    if [ -x /usr/local/bin/brew ]; then
        echo /usr/local/bin/brew
        return 0
    fi

    return 1
}

ensure_homebrew() {
    local brew_bin

    if brew_bin=$(resolve_homebrew); then
        echo "✅ Homebrew already installed"
    else
        echo "🍺 Installing Homebrew for nix-darwin Homebrew activation..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        brew_bin=$(resolve_homebrew) || {
            echo "❌ Homebrew installation finished, but brew was not found."
            exit 1
        }
    fi

    eval "$("$brew_bin" shellenv)"
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
    check_darwin_user
    ensure_homebrew
    backup_etc_file "/etc/shells"

    DARWIN_FLAKE="$HOME/.config/nix#default"
    
    # Use direct flake configuration
    if ! command -v darwin-rebuild >/dev/null 2>&1; then
        run_as_root nix run nix-darwin -- switch --flake "$DARWIN_FLAKE"
    else
        run_as_root bash "$(command -v darwin-rebuild)" switch --flake "$DARWIN_FLAKE"
    fi
    
    echo "🏠 Updating user environment..."

    activate_home_manager_flake "$HOME/.config/nix#homeConfigurations.macos-aarch64"
else
    echo "🐧 Updating Linux environment..."

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
    homeConfigurations.default = config.lib.mkHomeConfig {
      username = "$USER";
      system = "$HM_SYSTEM";
    };
  };
}
EOF

    activate_home_manager_flake "$TEMP_FLAKE#homeConfigurations.default"

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
