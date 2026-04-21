{
  config,
  pkgs,
  pkgsUnstable ? pkgs,
  ...
}:

{
  programs.zellij = {
    enable = true;
    package = pkgsUnstable.zellij;
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
