{
  description = "Cross-platform development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin }:
    let
      mkDarwinConfig = username: nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit username; };
        modules = [
          ({ pkgs, ... }: {
            # Required nix-darwin settings
            system.stateVersion = 6;
            system.primaryUser = username;
            nix.enable = false;
            
            # macOS system preferences
            system.defaults = {
              NSGlobalDomain = {
                _HIHideMenuBar = false;
                InitialKeyRepeat = 15;
                KeyRepeat = 2;
                AppleShowAllExtensions = true;
                AppleInterfaceStyle = "Dark";
                # Disable automatic text corrections
                NSAutomaticCapitalizationEnabled = false;
                NSAutomaticDashSubstitutionEnabled = false;
                NSAutomaticPeriodSubstitutionEnabled = false;
                NSAutomaticQuoteSubstitutionEnabled = false;
                NSAutomaticSpellingCorrectionEnabled = false;
                # Enable full keyboard access for all controls
                AppleKeyboardUIMode = 3;
                # Disable press-and-hold for keys in favor of key repeat
                ApplePressAndHoldEnabled = false;
              };
              
              dock = {
                autohide = true;
                show-recents = false;
                tilesize = 16;  # Minimum dock size
                mru-spaces = false;  # Don't rearrange spaces based on most recent use
              };
              
              finder = {
                AppleShowAllFiles = true;
                CreateDesktop = false;  # Hide desktop icons
                FXDefaultSearchScope = "SCcf";  # Search current folder by default
                ShowPathbar = true;
                ShowStatusBar = true;
              };
              
              trackpad = {
                Clicking = true;  # Tap to click
                TrackpadRightClick = true;
              };
              
              screencapture = {
                location = "~/Desktop/Screenshots";
                type = "png";
              };
            };
            
            # Custom preferences that nix-darwin doesn't support natively
            system.defaults.CustomUserPreferences = {
              "com.apple.menuextra.clock" = {
                ShowSeconds = true;
              };
              "com.apple.SoftwareUpdate" = {
                ScheduleFrequency = 1;
              };
              "com.apple.screencapture" = {
                "include-date" = false;
              };
            };
            
            # Apply settings immediately and create directories
            system.activationScripts.extraActivation.text = ''
              /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
              sudo -u ${username} mkdir -p /Users/${username}/Desktop/Screenshots
            '';
            
            # Set default shell to nushell
            users.users.${username} = {
              home = "/Users/${username}";
              shell = pkgs.nushell;
            };
            
            # Add nushell to system shells
            environment.shells = with pkgs; [ nushell fish bash zsh ];
            
            # macOS-specific packages via Homebrew
            homebrew = {
              enable = true;
              brews = [ ];
              casks = [ "battery" "ghostty" "intellij-idea" "ollama" ];
            };
          })
        ];
      };
      
      mkHomeConfig = username: system: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [ ./modules/home.nix ];
        extraSpecialArgs = { inherit username; };
      };
    in
    {
      # Functions to create configurations
      lib.mkDarwinConfig = mkDarwinConfig;
      lib.mkHomeConfig = mkHomeConfig;
      
      # Default configurations for convenience
      darwinConfigurations.default = mkDarwinConfig "jdangerhofer";
      
      homeConfigurations = {
        "macos-aarch64" = mkHomeConfig "jdangerhofer" "aarch64-darwin";
        "linux-x86_64" = mkHomeConfig "jdangerhofer" "x86_64-linux";
        "linux-aarch64" = mkHomeConfig "jdangerhofer" "aarch64-linux";
      };
    };
}