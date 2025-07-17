{ config, pkgs, ... }:

{
  programs.helix = {
    enable = true;
    settings = {
      theme = "tokyonight";
      editor = {
        soft-wrap = {
          enable = true;
        };
      };
    };
  };
}