eval "$(/opt/homebrew/bin/brew shellenv)"

########################################

export GOPATH=$HOME/.go
export PATH=$PATH:$GOPATH/bin

export PNPM_HOME="/Users/jdangerhofer/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

export PATH="$HOME/.cargo/bin:$PATH"

########################################

# tea -- https://github.com/teaxyz/cli
source <(tea --magic)

########################################

eval "$(starship init zsh)"

########################################

# # https://gist.github.com/bmhatfield/cc21ec0a3a2df963bffa3c1f884b676b
# if [ -f ~/.gnupg/.gpg-agent-info ] && [ -n "$(pgrep gpg-agent)" ]; then
#     source ~/.gnupg/.gpg-agent-info
#     export GPG_AGENT_INFO
# else
#     eval $(gpg-agent --daemon --write-env-file ~/.gnupg/.gpg-agent-info)
# fi
export GPG_TTY=$(tty)

########################################

alias b='brew'
alias g=git
alias k='kubectl'

########################################

brew_backup() {
  brew bundle dump --force --describe --file .Brewfile
}

brew_restore() {
  brew bundle --file .Brewfile
}

########################################

# bun completions
[ -s "/Users/jdangerhofer/.bun/_bun" ] && source "/Users/jdangerhofer/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

########################################

source /Users/jdangerhofer/.docker/init-zsh.sh || true # Added by Docker Desktop

########################################

# Shell autocompletions
autoload -Uz compinit
compinit

source <(kubectl completion zsh)
source ~/.zsh/zsh-z/zsh-z.plugin.zsh
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh