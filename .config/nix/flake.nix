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
      # macOS configuration
      darwinConfigurations."jdangerhofer-mac" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          home-manager.darwinModules.home-manager
          {
            # macOS-specific settings
            homebrew = {
              enable = true;
              brews = [ ];
              casks = [ "ghostty" "intellij-idea" ];
            };
            
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.jdangerhofer = import ./home.nix;
            };
          }
        ];
      };

      # Linux configuration
      homeConfigurations."jdangerhofer" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
}