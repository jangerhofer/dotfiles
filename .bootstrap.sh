#!/bin/bash

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
