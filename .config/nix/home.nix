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
    thefuck
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
      dotfiles = "git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME";
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
    '';
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