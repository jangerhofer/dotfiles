{ config, pkgs, lib, username ? "user", ... }:

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
    ./ssh.nix
    ./lazygit.nix
    ./fonts.nix
    ./cloud.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "23.11";

  # Development packages
  home.packages = with pkgs; [
    starship
    pay-respects  # replacement for thefuck
    git
    curl
    ripgrep
    lazygit
    lazydocker
    yt-dlp
    zellij
    btop
    
    # CLI utilities (migrated from homebrew)
    fd             # Simple, fast alternative to find
    fzf            # Command-line fuzzy finder
    jq             # Lightweight JSON processor
    tree           # Display directories as trees
    wget           # Internet file retriever
    
    # Development tools (migrated from homebrew)
    gh             # GitHub command-line tool
    delta          # Syntax-highlighting pager for git and diff output
    git-lfs        # Git extension for versioning large files
    git-sizer      # Compute various size metrics for a Git repository
    awscli         # Official Amazon AWS command-line interface
    
    # Kubernetes tools (migrated from homebrew)
    kubectl        # Kubernetes command-line interface
    helm           # Kubernetes package manager
    
    # Programming languages (migrated from homebrew)
    go             # Go programming language
    nodejs         # Node.js runtime
    python311      # Python 3.11
    rustup         # Rust toolchain installer
    
    # System utilities
    tmux           # Terminal multiplexer
    mtr            # Network diagnostic tool
    rsync          # Fast incremental file transfer
    nmap           # Network mapper
    stress         # System stress testing
    telnet         # Network utility
    
    # Additional CLI tools (migrated from homebrew)
    bun            # JavaScript runtime and bundler
    cloudflared    # Cloudflare tunnel client
    minicom        # Serial communication program
    mosh           # Mobile shell (SSH alternative)
    nnn            # Terminal file manager
    redis          # In-memory data store
    watchman       # File watching service
    yq             # YAML processor
    zig            # Programming language
    
    # Kubernetes additional tools
    kubie          # Kubernetes context switcher
    kustomize      # Kubernetes configuration management
    
    # Development tools
    rust-analyzer  # Rust language server (if not already via rustup)
    
    # Nix development tools
    nix-tree       # Nix dependency tree viewer
    nix-output-monitor  # Better nix build output
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    # macOS-specific tools
    mas            # Mac App Store CLI
  ];


  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}