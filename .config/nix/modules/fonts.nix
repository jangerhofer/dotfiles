{ config, pkgs, ... }:

{
  # Enable font management
  fonts.fontconfig.enable = true;
  
  home.packages = with pkgs; [
    # Essential programming fonts (new nerd-fonts namespace)
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.sauce-code-pro
    nerd-fonts.ubuntu-mono
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.inconsolata
    nerd-fonts.roboto-mono
    nerd-fonts.meslo-lg
    nerd-fonts.victor-mono
    nerd-fonts.iosevka
    nerd-fonts.anonymice
    nerd-fonts.space-mono
    nerd-fonts.go-mono
    
    # Additional useful fonts
    jetbrains-mono
    fira-code
    inconsolata
  ];
}