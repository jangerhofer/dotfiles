{ config, pkgs, ... }:

{
  # Fish shell configuration
  programs.fish = {
    enable = true;
    plugins = [
      { name = "z"; src = pkgs.fishPlugins.z; }
      { name = "sponge"; src = pkgs.fishPlugins.sponge; }
    ];
    shellAliases = {
      b = "brew";
      g = "git";
      k = "kubectl";
      d = "lazydocker";
      lg = "lazygit";
      yt = "yt-dlp";
      zj = "zellij";
      claude = "/Users/jdangerhofer/.claude/local/claude";
      dt = "git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME";
      dtlg = "lazygit --git-dir=$HOME/.dotfiles/ --work-tree=$HOME";
      hm = "home-manager switch --flake ~/.config/nix#jdangerhofer-mac";
      
      # History management
      hsync = "history --merge";
      
      # Nix aliases
      nb = "nix build";
      nd = "nix develop";
      nf = "nix flake";
      ns = "nix shell";
      nr = "nix run";
      nfc = "nix flake check";
      nfu = "nix flake update";
      nom = "nix-output-monitor";
      nt = "nix-tree";
    };
    shellInit = ''
      # Clear shell greeting
      set -g fish_greeting
      
      # Fix termcap errors for programs that don't recognize ghostty
      if test "$TERM" = "xterm-ghostty"
          set -gx TERM xterm-256color
      end
      
      # Ensure nix profiles are in PATH
      if test -d ~/.nix-profile/bin
          set -gx PATH ~/.nix-profile/bin $PATH
      end
      if test -d /nix/var/nix/profiles/default/bin
          set -gx PATH /nix/var/nix/profiles/default/bin $PATH
      end
      
      # Golang
      set -gx GOPATH $HOME/.go
      set -gx PATH $PATH $GOPATH/bin
      
      # Initialize thefuck (now pay-respects)
      pay-respects fish | source
    '';
    
    # Fish functions
    functions = {
      brew_backup = "brew bundle dump --force --describe --file .Brewfile";
      brew_restore = "brew bundle --file .Brewfile";
      
      idea = {
        body = ''
          /Applications/IntelliJ\ IDEA.app/Contents/MacOS/idea $argv >/dev/null 2>&1 &
          disown
        '';
        description = "Launch IntelliJ IDEA";
      };
      
      i = {
        body = ''
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
              echo "Usage: i <directory>"
          end
        '';
        description = "Launch IntelliJ IDEA with directory resolution";
      };
      
      sync_s3 = {
        body = ''
          aws s3 sync "s3://controller-development/control/$argv[1]" "data/control/$argv[1]"
        '';
        description = "Sync S3 data for given timestamp";
      };
    };
  };

  # Fish plugin files (until we can migrate them to nix)
  home.file = {
    ".config/fish/completions".source = ../configs/fish/completions;
    ".config/fish/conf.d".source = ../configs/fish/conf.d;
    ".config/fish/functions".source = ../configs/fish/functions;
  };
}