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
      system = "x86_64-linux"; # Change to "aarch64-darwin" for Apple Silicon Mac
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # macOS configuration (nix-darwin only - system preferences)
      darwinConfigurations."jdangerhofer-mac" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          {
            # Required nix-darwin settings
            system.stateVersion = 6;
            system.primaryUser = "jdangerhofer";
            nix.enable = false;
            
            # macOS system preferences
            system.defaults = {
              NSGlobalDomain = {
                _HIHideMenuBar = true;
                InitialKeyRepeat = 15;
                KeyRepeat = 2;
                AppleShowAllExtensions = true;
                AppleInterfaceStyle = "Dark";
              };
              
              dock = {
                autohide = true;
              };
              
              finder = {
                AppleShowAllFiles = true;
              };
              
              screencapture = {
                location = "~/Desktop/Screenshots";
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
            };
            
            # Apply settings immediately and create directories
            system.activationScripts.extraActivation.text = ''
              /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
              sudo -u jdangerhofer mkdir -p /Users/jdangerhofer/Desktop/Screenshots
            '';
            
            # macOS-specific packages via Homebrew
            homebrew = {
              enable = true;
              brews = [ ];
              casks = [ "ghostty" "intellij-idea" ];
            };
          }
        ];
      };
      
      # macOS Home Manager configuration (standalone)
      homeConfigurations."jdangerhofer-mac" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./modules/home.nix ];
      };

      # Linux configuration
      homeConfigurations."jdangerhofer" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./modules/home.nix ];
      };
    };
}