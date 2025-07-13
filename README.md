# dotfiles

Personal dotfiles managed with a bare Git repository.

## Quick Setup

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Clone dotfiles as bare repository
git clone --bare https://github.com/jangerhofer/dotfiles.git $HOME/.dotfiles

# Create alias for managing dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Backup any existing conflicting files
mkdir -p ~/.config-backup
dotfiles checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} ~/.config-backup/{}

# Checkout dotfiles
dotfiles checkout

# Hide untracked files (already configured in repo)
dotfiles config --local status.showUntrackedFiles no

# Restore Homebrew packages
brew_restore

# Set up fish shell
./.bootstrap.sh
```

*Note: Fish config includes the `dotfiles` alias automatically after setup.*

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
