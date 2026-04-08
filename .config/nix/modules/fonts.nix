{ config, pkgs, ... }:

{
  # Font installation is owned by nix-darwin on macOS.
  fonts.fontconfig.enable = false;
  home.packages = [ ];
}
