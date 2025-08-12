{ config, pkgs, ... }:

{
  # Ghostty terminal configuration
  home.file.".config/ghostty/config".text = ''
    theme = nord
  '';
}