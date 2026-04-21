{
  config,
  pkgs,
  lib,
  username ? "user",
  enableMediaServer ? false,
  ...
}:

let
  homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
  nixMaintenanceScript = pkgs.writeShellScript "nix-maintenance" ''
    set -eu

    "${config.home.profileDirectory}/bin/home-manager" expire-generations '-30 days'
    "${pkgs.nix}/bin/nix-collect-garbage" --delete-older-than 30d
    "${pkgs.nix}/bin/nix" store gc
  '';
  sharedPathEntries =
    [
      "${homeDirectory}/.nix-profile/bin"
      "/nix/var/nix/profiles/default/bin"
      "${homeDirectory}/.local/bin"
      "${homeDirectory}/.go/bin"
      "${homeDirectory}/.cargo/bin"
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      "/run/current-system/sw/bin"
      "/opt/homebrew/bin"
      "/usr/local/bin"
      "${homeDirectory}/.orbstack/bin"
    ];
  sharedSessionPath = lib.concatStringsSep ":" sharedPathEntries;
in
{
  _module.args.sharedPathEntries = sharedPathEntries;

  imports = [
    ./git.nix
    ./starship.nix
    ./btop.nix
    ./helix.nix
    ./ghostty.nix
    ./zellij.nix
    ./k9s.nix
    ./nushell.nix
    ./ssh.nix
    ./lazygit.nix
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
    with pkgs;
    [
      starship
      pay-respects
      git
      curl
      ripgrep
      lazygit
      lazydocker
      btop

      # CLI utilities (migrated from homebrew)
      fd
      fzf
      jq
      tree
      wget

      # Development tools (migrated from homebrew)
      gh
      delta
      git-lfs
      git-sizer

      # Kubernetes tools (migrated from homebrew)
      kubectl
      kubernetes-helm

      # Programming languages (migrated from homebrew)
      go
      nodejs
      pnpm
      python311
      rustup

      # System utilities
      bat
      eza
      tmux
      mtr
      rsync
      nmap
      stress
      inetutils

      # Additional CLI tools (migrated from homebrew)
      bun
      cloudflared
      ghidra
      k9s
      minicom
      mosh
      nnn
      redis
      wasm-pack
      watchman
      yq
      zig

      # Kubernetes additional tools
      kubie
      kustomize

      # Development tools
      uv
      caddy

      # Nix development tools
      nixd
      nixfmt-rfc-style
      statix
      deadnix
      nix-tree
      nix-output-monitor
      nix-index
      
      # Embedded development tools
      gcc-arm-embedded
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      # macOS-specific tools
      mas
      utm
    ];

  # Allow unfree packages (required for terraform and other BSL/commercial packages)
  nixpkgs.config.allowUnfree = true;

  # Keep common editor and PATH defaults consistent outside Nushell too.
  home.sessionVariables =
    {
      EDITOR = "hx";
      VISUAL = "hx";
      PATH = "$PATH:${sharedSessionPath}";
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      STM32CubeMX_PATH = "/Applications/STMicroelectronics/STM32CubeMX.app/Contents/Resources";
      STM32_PRG_PATH =
        "/Applications/STMicroelectronics/STM32Cube/STM32CubeProgrammer/STM32CubeProgrammer.app/Contents/MacOs/bin";
    };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Keep fallback shells declarative too.
  programs.zsh.enable = true;

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
    enableNushellIntegration = true;
    nix-direnv.enable = true;
  };

  # Periodic cleanup for Home Manager generations and user-reachable store data.
  launchd.agents.nix-maintenance = {
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
  launchd.agents.nix-store-optimise = {
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
  
  # Caddy proxy service for Pi devices
  launchd.agents.caddy-pi-proxy = {
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
