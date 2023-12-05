if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
end

alias b='brew'
alias g='git'
alias k='kubectl'
alias d='lazydocker'
alias lg='lazygit'
alias yt='yt-dlp'


########################################
# Golang
########################################

set -gx GOPATH $HOME/.go
set -gx PATH $PATH $GOPATH/bin

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

set -gx PATH $PATH '/Applications/IntelliJ IDEA.app/Contents/MacOS'

########################################
# Node
########################################

set -gx PNPM_HOME "/Users/jdangerhofer/Library/pnpm"
set -gx PATH $PNPM_HOME $PATH
