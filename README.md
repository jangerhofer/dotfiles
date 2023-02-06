# dotfiles
Personal `dotfiles`.


## Steps
- `git init` + `git remote add  origin  https://github.com/jangerhofer/dotfiles.git` + `git fetch` + `git checkout -b master --track origin/master`
- `git submodule init` + `git submodule update` to pull down `zsh` plugins
- `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- `brew_restore`
