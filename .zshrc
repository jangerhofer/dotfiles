# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
autoload -U +X compinit && compinit

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

source ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme

########################################

source ~/.zsh/zsh-z/zsh-z.plugin.zsh
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source <(kubectl completion zsh)
zstyle ':completion:*' menu select

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

export PATH=/Users/jdangerhofer/go/bin:$PATH

export PNPM_HOME="/Users/jdangerhofer/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

export PATH="$HOME/.cargo/bin:$PATH"

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

eval $(/opt/homebrew/bin/brew shellenv)


########################################

alias g=git
alias k='kubectl'

########################################

# https://gist.github.com/bmhatfield/cc21ec0a3a2df963bffa3c1f884b676b
export GPG_TTY=$(tty)