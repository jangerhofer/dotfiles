{ config, pkgs, ... }:

{
  # K9s configuration
  home.file = {
    ".config/k9s/aliases.yaml".source = ../configs/k9s/aliases.yaml;
    ".config/k9s/config.yaml".source = ../configs/k9s/config.yaml;
    ".config/k9s/skins/nord.yaml".source = ../configs/k9s/skins/nord.yaml;
  };
}