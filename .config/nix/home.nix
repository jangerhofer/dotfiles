{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "jdangerhofer";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/jdangerhofer" else "/home/jdangerhofer";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "23.11";

  # Development packages
  home.packages = with pkgs; [
    fish
    starship
    pay-respects  # replacement for thefuck
    git
    curl
    ripgrep
    lazygit
    lazydocker
    yt-dlp
    zellij
  ];

  # Fish shell configuration
  programs.fish = {
    enable = true;
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
    };
    shellInit = ''
      # Clear shell greeting
      set -g fish_greeting
      
      # Fix termcap errors for programs that don't recognize ghostty
      if test "$TERM" = "xterm-ghostty"
          set -gx TERM xterm-256color
      end
      
      # Golang
      set -gx GOPATH $HOME/.go
      set -gx PATH $PATH $GOPATH/bin
      
      # Initialize thefuck (now pay-respects)
      pay-respects --alias | source
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

  # Starship prompt
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "jdangerhofer";
    userEmail = "your-email@example.com"; # Update this
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}