function install-nerd-fonts --description "Install all available nerd fonts via Homebrew"
    brew search '/font-.*-nerd-font/' | awk '{ print $1 }' | xargs -I{} brew install --cask {} || true
end