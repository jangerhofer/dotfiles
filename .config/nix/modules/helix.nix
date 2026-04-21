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
      # Make Ctrl-a copy the entire buffer to the system clipboard.
      keys.normal = {
        "C-a" = [
          "select_all"
          "yank_to_clipboard"
        ];
      };
    };
  };

  # Helix themes
  home.file.".config/helix/themes/nord.toml".source = ../configs/helix/themes/nord.toml;
}
