#!/bin/bash
set -euo pipefail

# Detect operating system
OS="$(uname -s)"
case "${OS}" in
    Darwin*)    IS_MAC=true;;
    *)          IS_MAC=false;;
esac

# Mac-specific preferences setup
if [ "$IS_MAC" = true ]; then
    echo "[Setup] Configuring macOS preferences"
    
    # Disable sound effects. For example when taking a screenshot.
    defaults write "Apple Global Domain" com.apple.sound.uiaudio.enabled -int 0
    defaults write NSGlobalDomain _HIHideMenuBar -bool true

    # Faster keyboard execution.
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    defaults write NSGlobalDomain KeyRepeat -int 2

    # Dock tweaks like auto hide.
    defaults write com.apple.dock autohide -int 1

    killall Dock

    # Clock with seconds. Needs a restart.
    defaults write "com.apple.menuextra.clock" ShowSeconds -int 1

    # Show all extensions in Finder.
    defaults write "Apple Global Domain" AppleShowAllExtensions -int 1

    # Show dot files in finder.
    defaults write com.apple.Finder AppleShowAllFiles true
    killall Finder

    # Restart the service in order to propagate changes.
    killall SystemUIServer

    # Check for software updates daily, not just once per week
    defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
    echo "[Setup] Software updates checking daily"

    # Save screenshots in ~/Desktop/Screenshots folder
    mkdir -p $HOME/Desktop/Screenshots
    defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"
    echo "[Setup] Screenshots now will appear @ $HOME/Desktop/Screenshots"

    defaults write -globalDomain AppleInterfaceStyle "Dark"
    killall Dock
else
    echo "[Setup] Running on ${OS} - skipping macOS-specific setup"
fi

# The full path of the fish shell
FISH_PATH="$(which fish)"

# Check if fish is installed
if [ -z "$FISH_PATH" ]; then
    echo "Fish shell is not installed. Please install it first."
    exit 1
fi

# Add fish to /etc/shells if it's not already there
if ! grep -Fxq "$FISH_PATH" /etc/shells; then
    echo "Adding fish to /etc/shells"
    echo "$FISH_PATH" | sudo tee -a /etc/shells
fi

# Change the default shell for the current user
chsh -s "$FISH_PATH"
