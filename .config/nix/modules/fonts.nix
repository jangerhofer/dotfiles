{ config, pkgs, ... }:

{
  # Enable font management
  fonts.fontconfig.enable = true;
  
  home.packages = with pkgs; [
    # Essential programming fonts
    (nerdfonts.override { fonts = [ 
      "JetBrainsMono"
      "FiraCode" 
      "Hack"
      "SourceCodePro"
      "UbuntuMono"
      "DejaVuSansMono"
      "Inconsolata"
      "RobotoMono"
      "Meslo"
      "VictorMono"
      "CascadiaCode"
      "Iosevka"
      "AnonymousPro"
      "SpaceMono"
      "GoMono"
    ]; })
    
    # Additional useful fonts
    jetbrains-mono
    fira-code
    inconsolata
  ];
}