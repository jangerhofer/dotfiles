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
      
      # Initialize Homebrew
      if test -f /opt/homebrew/bin/brew
          eval "$(/opt/homebrew/bin/brew shellenv)"
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
      
      "pi-proxy-status" = {
        body = ''
          if curl -s http://localhost:2019/config/ >/dev/null 2>&1
              echo "Pi proxy is running"
              # Show current routes
              set -l routes (curl -s http://localhost:2019/config/apps/http/servers/srv0/routes | jq -r 'to_entries[] | select(.key | startswith("pi_")) | .key | sub("pi_"; "")')
              if test -n "$routes"
                  echo "Active tunnels:"
                  for route in $routes
                      echo "  - http://$route.localhost:7999"
                  end
              else
                  echo "No active tunnels"
              end
          else
              echo "Pi proxy is not running"
          end
        '';
        description = "Check Pi proxy status";
      };

      "pi-connect" = {
        body = ''
          set -l host $argv[1]
          set -l remote_port $argv[2]
          if test -z "$remote_port"
              set remote_port 8001
          end
          
          # Check for device mapping
          set -l config_file ~/.config/pi-devices.conf
          set -l friendly_name $host
          if test -f $config_file -a -n "$host"
              set -l mapped_host (grep "^$host=" $config_file 2>/dev/null | cut -d'=' -f2)
              if test -n "$mapped_host"
                  set host $mapped_host
              end
          end
          
          # Find an available local port starting from 8000
          set -l local_port 8000
          set -l max_port 8100
          set -l port_found 0
          
          while test $local_port -le $max_port
              # Check if port is in use
              if not lsof -i :$local_port >/dev/null 2>&1
                  set port_found 1
                  break
              end
              set local_port (math $local_port + 1)
          end
          
          if test $port_found -eq 0
              echo "No available ports found between 8000-8100"
              return 1
          end
          
          # Add route to Caddy via API
          set -l route_id "pi_$friendly_name"
          curl -s -X PUT "http://localhost:2019/config/apps/http/servers/srv0/routes/$route_id" \
            -H "Content-Type: application/json" \
            -d '{
              "match": [{"host": ["'$friendly_name'.localhost"]}],
              "handle": [{
                "@type": "reverse_proxy",
                "upstreams": [{"dial": "localhost:'$local_port'"}]
              }]
            }' >/dev/null
          
          echo "Starting tunnel from localhost:$local_port to $host:$remote_port..."
          ssh -N -f -L $local_port:localhost:$remote_port pi@$host -o PreferredAuthentications=password -o PubkeyAuthentication=no 2>/dev/null
          
          if test $status -eq 0
              # Get the tunnel PID
              set -l tunnel_pid (ps aux | grep "ssh.*-L $local_port:localhost:$remote_port.*$host" | grep -v grep | awk '{print $2}')
              
              echo "Tunnel established!"
              echo "Access at: http://$friendly_name.localhost:7999"
              echo "Direct port: http://localhost:$local_port"
              echo ""
              echo "Connecting to shell..."
              ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no pi@$host
              
              # Clean up after SSH session
              if test -n "$tunnel_pid"
                  echo "Cleaning up tunnel..."
                  kill $tunnel_pid
                  
                  # Remove route from Caddy
                  curl -s -X DELETE "http://localhost:2019/config/apps/http/servers/srv0/routes/$route_id" >/dev/null
              end
          else
              echo "Failed to establish tunnel"
              # Remove route if tunnel failed
              curl -s -X DELETE "http://localhost:2019/config/apps/http/servers/srv0/routes/$route_id" >/dev/null
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