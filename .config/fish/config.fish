if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
end

########################################
# Aliases
########################################

alias b='brew'
alias g='git'
alias k='kubectl'
alias d='lazydocker'
alias lg='lazygit'
alias yt='yt-dlp'

thefuck --alias | source

########################################
# Fish
########################################

# Clear shell greeting
set -g fish_greeting

########################################
# Golang
########################################

set -gx GOPATH $HOME/.go
set -gx PATH $PATH $GOPATH/bin

########################################
# Python
########################################
direnv hook fish | source


########################################
# Homebrew
########################################

function brew_backup
    brew bundle dump --force --describe --file .Brewfile
end

function brew_restore
    brew bundle --file .Brewfile
end

########################################
# Jetbrains
########################################

function idea
    /Applications/IntelliJ\ IDEA.app/Contents/MacOS/idea $argv > /dev/null 2>&1 &
end

########################################
# Node
########################################

set -gx PNPM_HOME "/Users/jdangerhofer/Library/pnpm"
set -gx PATH $PNPM_HOME $PATH