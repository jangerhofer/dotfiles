{
  config,
  pkgs,
  lib,
  username ? "user",
  ...
}:

{
  imports = [
    ./git.nix
    ./starship.nix
    ./btop.nix
    ./helix.nix
    ./nvim.nix
    ./ghostty.nix
    ./k9s.nix
    ./fish.nix
    ./nushell.nix
    ./ssh.nix
    ./lazygit.nix
    ./fonts.nix
    ./cloud.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = username;
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";

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
      yt-dlp
      zellij
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
      direnv
      minicom
      mosh
      nnn
      redis
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

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
  
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

