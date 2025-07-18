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
        modules = [
          {
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
              sudo -u ${username} mkdir -p /Users/${username}/Desktop/Screenshots
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
      darwinConfigurations.default = mkDarwinConfig "user";
      
      homeConfigurations = {
        "macos-aarch64" = mkHomeConfig "user" "aarch64-darwin";
        "linux-x86_64" = mkHomeConfig "user" "x86_64-linux";
        "linux-aarch64" = mkHomeConfig "user" "aarch64-linux";
      };
    };
}