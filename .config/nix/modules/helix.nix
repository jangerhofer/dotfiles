{ config, pkgs, ... }:

{
  programs.helix = {
    enable = true;
    settings = {
      theme = "nord";
      editor = {
        soft-wrap = {
          enable = true;
        };
      };
    };
  };

  # Helix themes
  home.file.".config/helix/themes/nord.toml".source = ../configs/helix/themes/nord.toml;
}