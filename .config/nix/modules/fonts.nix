{ config, pkgs, ... }:

{
  # Temporarily disable extra fonts until the set is updated for 25.05
  fonts.fontconfig.enable = false;
  home.packages = [ ];
}
