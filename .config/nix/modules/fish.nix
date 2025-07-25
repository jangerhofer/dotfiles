{ config, pkgs, ... }:

{
  # Fish shell configuration
  programs.fish = {
    enable = true;
    plugins = [
      { name = "z"; src = pkgs.fishPlugins.z; }
      { name = "sponge"; src = pkgs.fishPlugins.sponge; }
    ];
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
      hsync = "history --merge";
      
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
      # Update flake inputs to latest versions
      nup = "cd ~/.config/nix && nix flake update --flake ~/.config/nix";
      # Show what changed in flake.lock after update
      ncheck = "cd ~/.config/nix && git --git-dir=$HOME/.dotfiles --work-tree=$HOME diff HEAD -- .config/nix/flake.lock";
      # List available generations for rollback
      nroll = "home-manager generations";
      # Complete update workflow (update → check → apply)
      nfull = "cd ~/.config/nix && nix flake update --flake ~/.config/nix && git --git-dir=$HOME/.dotfiles --work-tree=$HOME diff HEAD -- .config/nix/flake.lock && hm";
      # Read home-manager news
      nnews = "home-manager news --flake ~/.config/nix#macos-aarch64";
    };
    shellInit = ''
      # Clear shell greeting
      set -g fish_greeting
      
      # Fix termcap errors for programs that don't recognize ghostty
      if test "$TERM" = "xterm-ghostty"
          set -gx TERM xterm-256color
      end
      
      # Ensure nix profiles are in PATH
      if test -d ~/.nix-profile/bin
          set -gx PATH ~/.nix-profile/bin $PATH
      end
      if test -d /nix/var/nix/profiles/default/bin
          set -gx PATH /nix/var/nix/profiles/default/bin $PATH
      end
      
      # Golang
      set -gx GOPATH $HOME/.go
      set -gx PATH $PATH $GOPATH/bin
      
      # Initialize thefuck (now pay-respects)
      pay-respects fish | source
      
      # Initialize direnv
      direnv hook fish | source
    '';
    
    # Fish functions
    functions = {
      brew_backup = "brew bundle dump --force --describe --file .Brewfile";
      brew_restore = "brew bundle --file .Brewfile";
      
      idea = {
        body = ''
          /Applications/IntelliJ\ IDEA.app/Contents/MacOS/idea $argv >/dev/null 2>&1 &
          disown
        '';
        description = "Launch IntelliJ IDEA";
      };
      
      i = {
        body = ''
          if test (count $argv) -eq 1
              # Use `z` to resolve the directory
              set dir (z -e $argv[1])
              if test -n "$dir"
                  /Applications/IntelliJ\ IDEA.app/Contents/MacOS/idea "$dir" >/dev/null 2>&1 &
                  disown
              else
                  echo "No match found for '$argv[1]'"
              end
          else
              echo "Usage: i <directory>"
          end
        '';
        description = "Launch IntelliJ IDEA with directory resolution";
      };
      
      sync_s3 = {
        body = ''
          aws s3 sync "s3://controller-development/control/$argv[1]" "data/control/$argv[1]"
        '';
        description = "Sync S3 data for given timestamp";
      };
      
      hm = {
        body = ''
          home-manager switch --flake ~/.config/nix#macos-aarch64
        '';
        description = "Switch home-manager configuration";
      };
      
      "up-or-search" = {
        body = ''
          # If we are already in search mode, continue
          if commandline --search-mode
              commandline -f history-search-backward
              return
          end

          # If we are navigating the pager, then up always navigates
          if commandline --paging-mode
              commandline -f up-line
              return
          end

          # We are not already in search mode.
          # If we are on the top line, start search mode,
          # otherwise move up
          set lineno (commandline -L)

          switch $lineno
              case 1
                  commandline -f history-search-backward
                  history merge # <-- ADDED THIS

              case '*'
                  commandline -f up-line
          end
        '';
        description = "Depending on cursor position and current mode, either search backward or move up one line";
      };
      
      "install-nerd-fonts" = {
        body = ''
          brew search '/font-.*-nerd-font/' | awk '{ print $1 }' | xargs -I{} brew install --cask {} || true
        '';
        description = "Install all available nerd fonts via Homebrew";
      };
      
      "pi-connect" = {
        body = ''
          set -l host $argv[1]
          set -l port $argv[2]
          if test -z "$port"
              set port 8001
          end
          
          # Check for device mapping
          set -l config_file ~/.config/pi-devices.conf
          if test -f $config_file -a -n "$host"
              set -l mapped_host (grep "^$host=" $config_file 2>/dev/null | cut -d'=' -f2)
              if test -n "$mapped_host"
                  set host $mapped_host
              end
          end
          
          # Kill any existing tunnel on this port
          set -l existing_pid (ps aux | grep "ssh.*-L $port:localhost:$port.*$host" | grep -v grep | awk '{print $2}')
          if test -n "$existing_pid"
              echo "Killing existing tunnel (PID: $existing_pid)..."
              kill $existing_pid
              sleep 1
          end
          
          echo "Starting tunnel on port $port..."
          ssh -N -f -L $port:localhost:$port pi@$host -o PreferredAuthentications=password -o PubkeyAuthentication=no 2>/dev/null
          
          if test $status -eq 0
              # Get the tunnel PID
              set -l tunnel_pid (ps aux | grep "ssh.*-L $port:localhost:$port.*$host" | grep -v grep | awk '{print $2}')
              
              echo "Tunnel established! Now connecting to shell..."
              ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no pi@$host
              
              # Kill tunnel after SSH session ends
              if test -n "$tunnel_pid"
                  echo "Cleaning up tunnel (PID: $tunnel_pid)..."
                  kill $tunnel_pid
              end
          else
              echo "Failed to establish tunnel"
              return 1
          end
        '';
        description = "Start SSH tunnel and connection to Pi";
      };
      
      "pi-disconnect" = {
        body = ''
          set -l host $argv[1]
          set -l port $argv[2]
          if test -z "$port"
              set port 8001
          end
          
          set -l existing_pid (ps aux | grep "ssh.*-L $port:localhost:$port.*$host" | grep -v grep | awk '{print $2}')
          if test -n "$existing_pid"
              echo "Killing tunnel to $host:$port (PID: $existing_pid)..."
              kill $existing_pid
          else
              echo "No tunnel found for $host:$port"
          end
        '';
        description = "Disconnect SSH tunnel to Pi";
      };
    };
  };

  # Fish plugin files (until we can migrate them to nix)
  home.file = {
    ".config/fish/completions".source = ../configs/fish/completions;
    ".config/fish/conf.d/z.fish".source = ../configs/fish/conf.d/z.fish;
    ".config/fish/functions/__z.fish".source = ../configs/fish/functions/__z.fish;
    ".config/fish/functions/__z_add.fish".source = ../configs/fish/functions/__z_add.fish;
    ".config/fish/functions/__z_clean.fish".source = ../configs/fish/functions/__z_clean.fish;
    ".config/fish/functions/__z_complete.fish".source = ../configs/fish/functions/__z_complete.fish;
  };
}