function brew_backup
    brew bundle dump --force --describe --file .Brewfile
end
