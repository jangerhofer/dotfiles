{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "JD Angerhofer";
    userEmail = "jd.angerhofer@gmail.com";
    
    # Enable difftastic for better diffs
    difftastic = {
      enable = true;
      display = "side-by-side";
    };
    
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPUy3gdzKIGR7Euq21r4O8hScZBj4wg9hJp9gXcOB00n";
      signByDefault = true;
    };
    
    extraConfig = {
      tag = {
        forceSignAnnotated = true;
        gpgSign = true;
      };
      rebase = {
        updateRefs = true;
      };
      help = {
        autocorrect = "immediate";
      };
      push = {
        gpgSign = "if-asked";
        default = "current";
        autoSetupRemote = true;
      };
      gpg = {
        format = "ssh";
        ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
      core = {
        editor = "nvim";
      };
      pull = {
        rebase = true;
      };
      filter.lfs = {
        process = "git-lfs filter-process";
        required = true;
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
      };
    };
    
    aliases = {
      # Add aliases
      a = "add";
      aa = "add --all";
      aliases = "!git config --get-regexp 'alias.*' | colrm 1 6 | sed 's/[ ]/ = /' | sort";
      ap = "add -p";
      
      # Branch aliases
      b = "branch";
      
      # Checkout aliases
      c = "checkout";
      cp = "checkout -p";
      
      # Commit aliases
      ca = "commit --amend";
      cach = "commit --amend -C HEAD";
      cam = "commit -a -m";
      cem = "commit --amend -m";
      cm = "commit -m";
      cwip = "commit -m \"WIP\"";
      cmph = ''!f() { git commit -m "$1" && git push; }; f'';
      
      # Diff aliases
      d = "diff";
      dc = "diff-tree --no-commit-id --name-status -r";
      dcsv = "diff --word-diff-regex=\"[^[:space:],]+\"";
      dnc = "diff --no-color";
      ds = "diff --staged";
      dsw = "diff --staged -w";
      dswd = "diff --staged --word-diff";
      dw = "diff -w";
      dwd = "diff --word-diff";
      
      # Difftastic aliases (as recommended in the manual)
      dlog = "-c diff.external=difft log --ext-diff";
      dshow = "-c diff.external=difft show --ext-diff";
      ddiff = "-c diff.external=difft diff";
      
      # Additional shortcuts from the manual
      dl = "-c diff.external=difft log -p --ext-diff";  # git log with patches
      dft = "-c diff.external=difft diff";  # git diff with difftastic
      
      # Fetch aliases
      f = "fetch";
      fa = "fetch --all";
      fgi = "rm -r --cached .";
      fu = "fetch upstream";
      
      # Log aliases
      l = "log";
      lc = "log --graph --pretty=format:\"%an: %s%C(yellow)%d%Creset %Cgreen(%cr)%Creset\" --date=relative";
      lch = "rev-parse HEAD";
      lcm = "show -s --format=%s";
      lm = ''!me=$(git config --get user.name); git log --oneline --author "$me"'';
      lo = "log --oneline";
      lodg = "log --oneline --decorate --graph";
      ls = "log --graph -10 --branches --remotes --tags  --format=format:'%Cgreen%h %Creset• %<(75,trunc)%s (%cN, %cr) %Cred%d' --date-order";
      
      # Merge aliases
      m = "merge";
      mm = "merge master";
      mum = "merge upstream/master";
      
      # Misc aliases
      noc = "rev-list HEAD --count";
      
      # Push aliases
      p = "cherry-pick";
      ph = "push";
      phf = "push --force-with-lease";
      pho = "push origin";
      phoa = "push origin --all";
      phom = "push origin master";
      phomt = "push origin master --tags";
      phou = "push origin -u";
      phoum = "push origin -u master";
      pl = "pull";
      
      # Reset aliases
      r = "reset";
      ra = "remote add";
      rao = "remote add origin";
      rau = "remote add upstream";
      rba = "rebase --abort";
      rbc = "rebase --continue";
      rbi = "rebase -i";
      rbih1 = "rebase -i HEAD~1";
      rbiom = "rebase -i origin/master";
      rbm = "rebase master";
      rbs = "rebase --skip";
      rc = "mergetool"; # Resolve conflicts
      rh = "reset --hard";
      rha = "reset HEAD .";
      rhom = "reset --hard origin/master";
      rlc = "reset --soft HEAD~1";
      rpo = "remote prune origin";
      rpu = "remote prune upstream";
      rro = "remote remove origin";
      rru = "remote remove upstream";
      rs = "reset --soft";
      
      # Status aliases
      s = "status";
      sc = ''!f() { git switch "$1" 2>/dev/null || git switch -c "$1"; }; f''; # Switch/Create
      si = "status --ignored";
      sp = "stash -p";
      sw = "switch";
      swip = "stash -m \"WIP\"";
      swc = "switch -c"; # Switch-create
      
      # Tag aliases
      ft = ''!f(){ git tag --contains $1; };f'';
      squash = ''!f(){ git reset --soft HEAD~$1 && git commit --edit -m"$(git log --format=%B --reverse HEAD..HEAD@{1})"; };f'';
      
      # Stash aliases
      st = "stash";
      sta = "stash apply";
      
      # Tree aliases
      trm = "ls-tree -r master --name-only";
      
      # Index aliases
      unwatch = "update-index --assume-unchanged";
      up = "pull --rebase --autostash";
      watch = "update-index --no-assume-unchanged";
      
      # Worktree aliases
      wta = "worktree add";                                    # Add worktree: wta <path> <branch>
      wtac = ''!f() { git worktree add -b $2 $1 $3; }; f'';   # Create new branch + worktree: wtac <path> <new-branch> [start-point]
      wtl = "worktree list";                                   # List all worktrees
      wtls = "worktree list --porcelain";                      # List worktrees (machine-readable)
      wtrm = "worktree remove";                                # Remove worktree: wtrm <path>
      wtrmf = "worktree remove --force";                       # Force remove worktree (even if dirty)
      wtp = "worktree prune";                                  # Remove stale worktree admin files
      wtpr = "worktree prune --dry-run";                       # Show what would be pruned
      
      # Tag alias
      t = "tag";
    };
  };
}