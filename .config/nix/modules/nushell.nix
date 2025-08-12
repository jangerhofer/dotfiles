{ config, pkgs, lib, ... }:

{
  programs.nushell = {
    enable = true;
    
    # Environment variables
    environmentVariables = {
      EDITOR = "hx";
      GOPATH = "$HOME/.go";
    };
    
    # Shell aliases - all from fish config
    shellAliases = {
      b = "brew";
      g = "git";
      k = "kubectl";
      d = "lazydocker";
      lg = "lazygit";
      yt = "yt-dlp";
      zj = "zellij";
      claude = "/Users/jdangerhofer/.claude/local/claude";
      dt = "git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME";
      dtlg = "lazygit --git-dir=$HOME/.dotfiles/ --work-tree=$HOME";
      
      # History management
      hsync = "history merge";
      
      # Nix aliases
      nb = "nix build";
      nd = "nix develop";
      nf = "nix flake";
      ns = "nix shell";
      nr = "nix run";
      nfc = "nix flake check";
      nfu = "nix flake update";
      nom = "nix-output-monitor";
      nt = "nix-tree";
      
      # Nix update workflow aliases
      nup = "cd ~/.config/nix; nix flake update --flake ~/.config/nix";
      ncheck = "cd ~/.config/nix; git --git-dir=$HOME/.dotfiles --work-tree=$HOME diff HEAD -- .config/nix/flake.lock";
      nroll = "home-manager generations";
      nfull = "cd ~/.config/nix; nix flake update --flake ~/.config/nix; git --git-dir=$HOME/.dotfiles --work-tree=$HOME diff HEAD -- .config/nix/flake.lock; hm";
      nnews = "home-manager news --flake ~/.config/nix#macos-aarch64";
    };
    
    # Nushell configuration
    extraConfig = ''
      # Load completions
      use ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/git/git-completions.nu *
      use ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/nix/nix-completions.nu *
      
      # Starship prompt
      $env.STARSHIP_SHELL = "nu"
      $env.PROMPT_COMMAND = {|| starship prompt }
      $env.PROMPT_COMMAND_RIGHT = ""
      
      # Custom functions
      
      # Brew backup/restore
      def brew_backup [] {
        brew bundle dump --force --describe --file .Brewfile
      }
      
      def brew_restore [] {
        brew bundle --file .Brewfile
      }
      
      # IntelliJ IDEA launcher
      def idea [...args] {
        bash -c $"/Applications/IntelliJ\\ IDEA.app/Contents/MacOS/idea ($args | str join ' ') >/dev/null 2>&1 &"
      }
      
      # IntelliJ IDEA with directory resolution using z
      def i [dir: string] {
        let resolved = (z query $dir | lines | first)
        if $resolved != "" {
          bash -c $"/Applications/IntelliJ\\ IDEA.app/Contents/MacOS/idea '($resolved)' >/dev/null 2>&1 &"
        } else {
          print $"No match found for '($dir)'"
        }
      }
      
      # S3 sync function
      def sync_s3 [timestamp: string] {
        aws s3 sync $"s3://controller-development/control/($timestamp)" $"data/control/($timestamp)"
      }
      
      # Home-manager switch
      def hm [] {
        home-manager switch --flake ~/.config/nix#macos-aarch64
      }
      
      # Darwin switch
      def dm [] {
        nix run nix-darwin -- switch --flake ~/.config/nix#default
      }
      
      # Combined nix switch (Darwin + home-manager)
      def nm [] {
        nix run nix-darwin -- switch --flake ~/.config/nix#default
      }
      
      # Install all nerd fonts
      def install-nerd-fonts [] {
        brew search '/font-.*-nerd-font/' 
        | lines 
        | each {|font| brew install --cask $font} 
        | ignore
      }
      
      # Pi device connection
      def pi [host: string, remote_port?: int = 8001] {
        mut actual_host = $host
        let config_file = "~/.config/pi-devices.conf" | path expand
        
        # Check for device mapping
        if ($config_file | path exists) {
          let mapping = (open $config_file | lines | where {|line| $line | str starts-with $"($host)="} | first)
          if $mapping != null {
            $actual_host = ($mapping | split column "=" | get column2.0)
          }
        }
        
        # Open browser in background
        print $"Opening browser tab to http://($actual_host):($remote_port) \(in background\)..."
        bash -c $"open -g 'http://($actual_host):($remote_port)'"
        print "Browser tab opened in background."
        
        # Connect via SSH
        print "Connecting to shell..."
        ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no $"pi@($actual_host)"
      }
      
      # Basic config
      $env.config = {
        show_banner: false
        edit_mode: vi
        
        history: {
          max_size: 100_000
          file_format: "sqlite"
          sync_on_enter: true
        }
        
        completions: {
          algorithm: "fuzzy"
          case_sensitive: false
        }
        
        hooks: {
          pre_prompt: [
            # Direnv hook
            {|| 
              if (which direnv | is-empty) { return }
              direnv export json | from json | default {} | load-env
            }
          ]
          env_change: {
            PWD: [
              # Z directory tracker hook
              {|before, after| 
                if (which zoxide | is-not-empty) {
                  zoxide add $after
                }
              }
            ]
          }
        }
      }
    '';
    
    # Environment setup
    extraEnv = ''
      # Clear greeting
      $env.config = ($env.config | upsert show_banner false)
      
      # Fix termcap for ghostty
      if $env.TERM? == "xterm-ghostty" {
        $env.TERM = "xterm-256color"
      }
      
      # Initialize Homebrew
      if ("/opt/homebrew/bin/brew" | path exists) {
        $env.PATH = ($env.PATH | prepend "/opt/homebrew/bin")
        # Load homebrew env vars
        /opt/homebrew/bin/brew shellenv | lines | parse "export {name}={value}" | reduce -f {} {|it, acc| $acc | upsert $it.name $it.value} | load-env
      }
      
      # Ensure nix profiles are in PATH
      if ("~/.nix-profile/bin" | path expand | path exists) {
        $env.PATH = ($env.PATH | prepend ("~/.nix-profile/bin" | path expand))
      }
      if ("/nix/var/nix/profiles/default/bin" | path exists) {
        $env.PATH = ($env.PATH | prepend "/nix/var/nix/profiles/default/bin")
      }
      
      # Golang
      $env.PATH = ($env.PATH | append $"($env.HOME)/.go/bin")
      
      # Initialize pay-respects (thefuck replacement)
      # Note: pay-respects doesn't have native nushell support yet
      # You can use it by typing 'pay-respects' after a failed command
    '';
  };
  
  home.packages = with pkgs; [
    nushell
    nu_scripts  # For completions
    zoxide      # Modern z replacement that works with nushell
  ];
}