{
  config,
  pkgs,
  lib,
  username ? "user",
  enableMediaServer ? false,
  homeManagerProfileName ? null,
  ...
}:

let
  enablePiProxy = false;
  profileName = if homeManagerProfileName == null then "" else homeManagerProfileName;
  isDarwin = pkgs.stdenv.isDarwin;
  isVpsProfile = profileName == "vps-aarch64";
  homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
  nixMaintenanceScript = pkgs.writeShellScript "nix-maintenance" ''
    set -eu

    "${config.home.profileDirectory}/bin/home-manager" expire-generations '-30 days'
    "${pkgs.nix}/bin/nix-collect-garbage" --delete-older-than 30d
    "${pkgs.nix}/bin/nix" store gc
  '';
  direnvNoCheck = pkgs.direnv.overrideAttrs (_old: {
    doCheck = false;
  });
  sharedPathEntries = [
    "${homeDirectory}/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
    "${homeDirectory}/.local/bin"
    "${homeDirectory}/.go/bin"
    "${homeDirectory}/.cargo/bin"
  ]
  ++ lib.optionals isDarwin [
    "/run/current-system/sw/bin"
    "/opt/homebrew/bin"
    "/usr/local/bin"
    "${homeDirectory}/.orbstack/bin"
  ];
  sharedSessionPath = lib.concatStringsSep ":" sharedPathEntries;
  corePackages = with pkgs; [
    starship
    pay-respects
    git
    curl
    ripgrep
    lazygit
    btop

    fd
    fzf
    jq
    tree
    wget

    gh
    delta
    git-lfs
    git-sizer

    kubectl
    kubernetes-helm
    k9s
    kubie
    kustomize

    bat
    eza
    tmux
    mtr
    rsync
    nmap
    inetutils

    nixd
    nixfmt-rfc-style
    statix
    deadnix
    nix-tree
    nix-output-monitor
    nix-index
  ];
  workstationPackages = with pkgs; [
    lazydocker

    go
    nodejs
    pnpm
    python311
    rustup

    bun
    cloudflared
    minicom
    mosh
    nnn
    redis
    wasm-pack
    watchman
    yq
    zig

    uv
    caddy
    cargo-binstall
    ffmpeg
    gemini-cli
    graphicsmagick
    imagemagick
    lefthook
    mprocs
    ollama
    yt-dlp

    gcc-arm-embedded
  ];
  darwinPackages = with pkgs; [
    mas
    utm
  ];
in
{
  _module.args.sharedPathEntries = sharedPathEntries;

  imports = [
    ./git.nix
    ./starship.nix
    ./btop.nix
    ./helix.nix
    ./zellij.nix
    ./k9s.nix
    ./nushell.nix
    ./ssh.nix
    ./lazygit.nix
  ]
  ++ lib.optionals (!isVpsProfile) [
    ./ghostty.nix
    ./cloud.nix
    ./media-server.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = username;
  home.homeDirectory = homeDirectory;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "23.11";

  # Development packages
  home.packages =
    corePackages
    ++ lib.optionals (!isVpsProfile) workstationPackages
    ++ lib.optionals isDarwin darwinPackages;

  # Allow unfree packages (required for terraform and other BSL/commercial packages)
  nixpkgs.config.allowUnfree = true;

  # Keep common editor and PATH defaults consistent outside Nushell too.
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    PATH = "$PATH:${sharedSessionPath}";
  }
  // lib.optionalAttrs isDarwin {
    STM32CubeMX_PATH = "/Applications/STMicroelectronics/STM32CubeMX.app/Contents/Resources";
    STM32_PRG_PATH = "/Applications/STMicroelectronics/STM32Cube/STM32CubeProgrammer/STM32CubeProgrammer.app/Contents/MacOs/bin";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # FIXME(upstream-home-manager): remove this override after Home Manager's
  # `installPackages` activation block switches from `nix profile install` to
  # `nix profile add`.
  home.activation.installPackages = lib.mkForce (
    lib.hm.dag.entryAfter [ "writeBoundary" ] (
      if config.submoduleSupport.externalPackageInstall then
        ''
          nixProfileRemove home-manager-path
        ''
      else
        ''
          function nixReplaceProfile() {
            local oldNix="$(command -v nix)"

            nixProfileRemove 'home-manager-path'

            run $oldNix profile add $1
          }

          if [[ -e ${config.home.profileDirectory}/manifest.json ]] ; then
            INSTALL_CMD="nix profile add"
            INSTALL_CMD_ACTUAL="nixReplaceProfile"
            LIST_CMD="nix profile list"
            REMOVE_CMD_SYNTAX='nix profile remove {number | store path}'
          else
            INSTALL_CMD="nix-env -i"
            INSTALL_CMD_ACTUAL="run nix-env -i"
            LIST_CMD="nix-env -q"
            REMOVE_CMD_SYNTAX='nix-env -e {package name}'
          fi

          if ! $INSTALL_CMD_ACTUAL ${config.home.path} ; then
            echo
            _iError $'Oops, Nix failed to install your new Home Manager profile!\n\nPerhaps there is a conflict with a package that was installed using\n"%s"? Try running\n\n    %s\n\nand if there is a conflicting package you can remove it with\n\n    %s\n\nThen try activating your Home Manager configuration again.' "$INSTALL_CMD" "$LIST_CMD" "$REMOVE_CMD_SYNTAX"
            exit 1
          fi
          unset -f nixReplaceProfile
          unset INSTALL_CMD INSTALL_CMD_ACTUAL LIST_CMD REMOVE_CMD_SYNTAX
        ''
    )
  );

  # Avoid noisy options.json generation on 25.11; use `nnews` to inspect news on demand.
  manual.manpages.enable = false;
  news.display = "silent";

  # Keep fallback shells declarative too, with the same tool precedence as Nushell.
  programs.zsh = {
    enable = true;
    initContent = lib.mkBefore ''
      _hm_path_entries=(
      ${lib.concatMapStringsSep "\n" (path: "  ${lib.escapeShellArg path}") sharedPathEntries}
      )
      _hm_existing_path_entries=()
      for _hm_path_entry in "''${_hm_path_entries[@]}"; do
        if [[ -d "$_hm_path_entry" ]]; then
          _hm_existing_path_entries+=("$_hm_path_entry")
        fi
      done
      path=("''${_hm_existing_path_entries[@]}" "''${path[@]}")
      typeset -U path
      export PATH
      unset _hm_path_entry _hm_path_entries _hm_existing_path_entries
    '';
  };

  home.file = {
    ".profile".text = ''
      if [ -e "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh" ]; then
        . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
      fi
    '';

    ".bash_profile".text = ''
      if [ -f "$HOME/.profile" ]; then
        . "$HOME/.profile"
      fi
    '';
  };

  # Manage direnv centrally and use nix-direnv's faster flake integration.
  programs.direnv = {
    enable = true;
    package = direnvNoCheck;
    enableNushellIntegration = true;
    nix-direnv.enable = true;
  };

  services.ollama = lib.mkIf (!isVpsProfile) {
    enable = true;
    package = pkgs.ollama;
  };

  # Periodic cleanup for Home Manager generations and user-reachable store data.
  launchd.agents.nix-maintenance = lib.mkIf isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${nixMaintenanceScript}" ];
      StartCalendarInterval = {
        Weekday = 1;
        Hour = 4;
        Minute = 30;
      };
      StandardOutPath = "${config.home.homeDirectory}/.cache/nix-maintenance.log";
      StandardErrorPath = "${config.home.homeDirectory}/.cache/nix-maintenance.log";
    };
  };

  # Deduplicate identical store files periodically to keep the Nix store compact.
  launchd.agents.nix-store-optimise = lib.mkIf isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.nix}/bin/nix"
        "store"
        "optimise"
      ];
      StartCalendarInterval = {
        Day = 1;
        Hour = 5;
        Minute = 0;
      };
      StandardOutPath = "${config.home.homeDirectory}/.cache/nix-maintenance.log";
      StandardErrorPath = "${config.home.homeDirectory}/.cache/nix-maintenance.log";
    };
  };

  # Caddy proxy service for Pi devices. Disabled unless the proxy config exists
  # and the machine opts in.
  launchd.agents.caddy-pi-proxy = lib.mkIf (isDarwin && enablePiProxy) {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.caddy}/bin/caddy"
        "run"
        "--config"
        "${config.home.homeDirectory}/.config/caddy/pi-proxy.json"
        "--adapter"
        "caddyfile"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/.config/caddy/caddy.log";
      StandardErrorPath = "${config.home.homeDirectory}/.config/caddy/caddy.log";
    };
  };
}
