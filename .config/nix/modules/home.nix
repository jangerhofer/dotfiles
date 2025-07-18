{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
    ./starship.nix
    ./btop.nix
    ./helix.nix
    ./nvim.nix
    ./ghostty.nix
    ./k9s.nix
    ./fish.nix
    ./ssh.nix
  ];
  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "jdangerhofer";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/jdangerhofer" else "/home/jdangerhofer";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "23.11";

  # Development packages
  home.packages = with pkgs; [
    starship
    pay-respects  # replacement for thefuck
    git
    curl
    ripgrep
    lazygit
    lazydocker
    yt-dlp
    zellij
    btop
    
    # Nix development tools
    nix-tree      # Nix dependency tree viewer
    nix-output-monitor  # Better nix build output
  ];


  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}