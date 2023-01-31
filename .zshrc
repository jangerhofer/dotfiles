# tea -- https://github.com/teaxyz/cli
export PATH="$HOME/.tea/tea.xyz/v*/bin:$PATH"
test -d "$HOME/.tea" && source <("$HOME/.tea/tea.xyz/v*/bin/tea" --magic --silent)

########################################

export GOPATH=$HOME/.go
export PATH=$PATH:$GOPATH/bin

export PNPM_HOME="/Users/jdangerhofer/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

export PATH="$HOME/.cargo/bin:$PATH"

########################################

eval "$(/opt/homebrew/bin/brew shellenv)"

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

# opam configuration
[[ ! -r /Users/jdangerhofer/.opam/opam-init/init.zsh ]] || source /Users/jdangerhofer/.opam/opam-init/init.zsh  > /dev/null 2> /dev/null

# `pyenv` config
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

########################################

# Shell autocompletions
autoload -Uz compinit
compinit

source <(kubectl completion zsh)
source ~/.zsh/zsh-z/zsh-z.plugin.zsh
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh