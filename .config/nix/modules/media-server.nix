{
  config,
  pkgs,
  lib,
  enableMediaServer ? false,
  ...
}:

let
  mediaServerEnabled = pkgs.stdenv.isDarwin && enableMediaServer;
  jellyfinDataDir = "${config.home.homeDirectory}/.local/share/jellyfin/data";
  jellyfinConfigDir = "${config.home.homeDirectory}/.config/jellyfin";
  jellyfinCacheDir = "${config.home.homeDirectory}/.cache/jellyfin";
  jellyfinLogDir = "${config.home.homeDirectory}/.local/state/jellyfin/log";
in
lib.mkIf mediaServerEnabled {
  home.packages = [ pkgs.jellyfin ];

  home.activation.jellyfinDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p \
      "${jellyfinDataDir}" \
      "${jellyfinConfigDir}" \
      "${jellyfinCacheDir}" \
      "${jellyfinLogDir}"
  '';

  launchd.agents.jellyfin = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.jellyfin}/bin/jellyfin"
        "--service"
        "--datadir"
        jellyfinDataDir
        "--configdir"
        jellyfinConfigDir
        "--cachedir"
        jellyfinCacheDir
        "--logdir"
        jellyfinLogDir
      ];
      WorkingDirectory = config.home.homeDirectory;
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
      StandardOutPath = "${jellyfinLogDir}/launchd.stdout.log";
      StandardErrorPath = "${jellyfinLogDir}/launchd.stderr.log";
    };
  };
}
