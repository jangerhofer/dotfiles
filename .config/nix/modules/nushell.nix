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
      l = "eza -la";
      claude = "/Users/jdangerhofer/.claude/local/claude";
      
      # History management (Nushell doesn't have history merge - it auto-syncs)
      # hsync = "history merge";  # Not needed in Nushell
      
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
      nroll = "home-manager generations";
      nnews = "home-manager news --flake ~/.config/nix#macos-aarch64";
      
      # macOS open utility
      f = "/usr/bin/open";
      
    };
    
    # Nushell configuration
    extraConfig = ''
      # Load completions
      use ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/git/git-completions.nu *
      use ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/nix/nix-completions.nu *
      
      
      # Disable nushell prompt indicators since we use starship
      $env.PROMPT_INDICATOR = ""
      $env.PROMPT_INDICATOR_VI_INSERT = ""  
      $env.PROMPT_INDICATOR_VI_NORMAL = ""
      
      # Custom functions
      
      # Dotfiles git commands
      def dt [...args] {
        git --git-dir $"($env.HOME)/.dotfiles/" --work-tree $env.HOME ...$args
      }
      
      def dtlg [] {
        lazygit --git-dir $"($env.HOME)/.dotfiles/" --work-tree $env.HOME
      }
      
      # Nix workflow functions
      def ncheck [] {
        cd $"($env.HOME)/.config/nix"
        git --git-dir $"($env.HOME)/.dotfiles" --work-tree $env.HOME diff HEAD -- .config/nix/flake.lock
      }
      
      def nup [] {
        cd $"($env.HOME)/.config/nix"
        nix flake update --flake $"($env.HOME)/.config/nix"
      }
      
      def nfull [] {
        cd $"($env.HOME)/.config/nix"
        nix flake update --flake $"($env.HOME)/.config/nix"
        git --git-dir $"($env.HOME)/.dotfiles" --work-tree $env.HOME diff HEAD -- .config/nix/flake.lock
        hm
      }
      
      # Zoxide integration with proper directory changing
      def --env z [dir?: string] {
        if ($dir | is-empty) {
          zoxide query -l
        } else {
          let result = (zoxide query $dir)
          if ($result | is-not-empty) {
            cd $result
          } else {
            print $"No match found for '($dir)'"
          }
        }
      }
      
      def --env zi [] {
        let result = (zoxide query -i)
        if ($result | is-not-empty) {
          cd $result
        }
      }
      
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
      
      # IntelliJ IDEA with directory resolution using zoxide
      def i [dir: string] {
        let resolved = (zoxide query $dir | lines | first)
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
        sudo nix run nix-darwin -- switch --flake ~/.config/nix#default
      }
      
      # Combined nix switch (Darwin + home-manager)
      def nm [] {
        sudo nix run nix-darwin -- switch --flake ~/.config/nix#default
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
          file_format: "sqlite"
          sync_on_enter: true
        }
        
        completions: {
          algorithm: "fuzzy"
          case_sensitive: false
        }
        
        cursor_shape: {
          vi_insert: "line"       # Vertical line cursor in insert mode
          vi_normal: "block"      # Block cursor in normal mode
        }
        
        keybindings: [
          {
            name: move_word_left_alt_h
            modifier: alt
            keycode: char_h
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: MoveWordLeft }
          }
          {
            name: move_word_right_alt_l
            modifier: alt
            keycode: char_l
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: MoveWordRight }
          }
          {
            name: move_word_left_alt_b
            modifier: alt
            keycode: char_b
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: MoveWordLeft }
          }
          {
            name: move_word_right_alt_f
            modifier: alt
            keycode: char_f
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: MoveWordRight }
          }
        ]
        
        
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