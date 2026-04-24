{ config, pkgs, ... }:

{
  # Work-specific Rhythm tooling.
  home.packages = [ pkgs.ghidra ];
}
