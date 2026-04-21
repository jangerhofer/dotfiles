{ config, pkgs, ... }:

{
  programs.zellij = {
    enable = true;
    settings = {
      theme = "nord";
    };
  };

  xdg.configFile."zellij/config.kdl".force = true;
}
