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
alias zj="zellij"

thefuck --alias | source


########################################
# Cursor
########################################

function c
    if test (count $argv) -eq 1
        # Use `z` to resolve the directory
        set dir (z -e $argv[1])
        if test -n "$dir"
            /Applications/Cursor.app/Contents/MacOS/Cursor "$dir" >/dev/null 2>&1 &
            disown
        else
            echo "No match found for '$argv[1]'"
        end
    else
        echo "Usage: c <directory>"
    end
end


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
    /Applications/IntelliJ\ IDEA.app/Contents/MacOS/idea $argv >/dev/null 2>&1 &
    disown
end

function i
    if test (count $argv) -eq 1
        # Use `z` to resolve the directory
        set dir (z -e $argv[1])
        if test -n "$dir"
            /Applications/IntelliJ\ IDEA.app/Contents/MacOS/idea "$dir" >/dev/null 2>&1 &
            disown
        else
            echo "No match found for '$argv[1]'"
        end
    else
        echo "Usage: idea <directory>"
    end
end


########################################
# Node
########################################

set -gx PNPM_HOME /Users/jdangerhofer/Library/pnpm
set -gx PATH $PNPM_HOME $PATH

test -e {$HOME}/.iterm2_shell_integration.fish; and source {$HOME}/.iterm2_shell_integration.fish

########################################
# Profound
########################################

function sync_s3 --argument-names run_timestamp; aws s3 sync "s3://controller-development/control/$run_timestamp" "data/control/$run_timestamp"; end 