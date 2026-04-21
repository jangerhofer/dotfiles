{ config, pkgs, ... }:

{
  programs.zellij = {
    enable = true;
    settings = {
      theme = "nord";
      keybinds = {
        unbind = [
          "Alt Left"
          "Alt Right"
          "Alt Up"
          "Alt Down"
        ];
      };
    };
  };

  xdg.configFile."zellij/config.kdl".force = true;
}
