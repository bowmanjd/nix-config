{
  description = "Jonathan Bowman nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    rust-overlay,
    ...
  } @ inputs: let
    inherit (self) outputs;
    inherit (nixpkgs) lib;
    systems = ["x86_64-linux"];
    forAllSystems = lib.genAttrs systems;

    # Add stable nixpkgs as overlay
    overlay-stable = final: prev: {
      stable = import inputs.nixpkgs-stable {
        system = final.system;
        config.allowUnfree = true;
      };
    };

    # Create a common function for NixOS configurations
    mkNixosSystem = {
      hostname,
      username,
      nixosConfigFile,
      homeConfigFile,
      extraModules ? [],
    }:
      nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules =
          [
            {
              nixpkgs.overlays = [overlay-stable rust-overlay.overlays.default];
              networking.hostName = hostname;
            }
            nixosConfigFile
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${username} = import homeConfigFile;
                extraSpecialArgs = {inherit inputs outputs;};
              };
            }
          ]
          ++ extraModules;
      };
  in {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    overlays = import ./overlays {inherit inputs;};

    # NixOS configuration entrypoint
    nixosConfigurations = {
      # Available through 'sudo nixos-rebuild switch --flake .#lappy386'
      lappy386 = mkNixosSystem {
        hostname = "lappy386";
        username = "bowmanjd";
        nixosConfigFile = ./nixos/lappy.nix;
        homeConfigFile = ./home-manager/home.nix;
      };

      # Available through 'sudo nixos-rebuild switch --flake .#work'
      work = mkNixosSystem {
        hostname = "jbowman-cargas";
        username = "jbowman";
        nixosConfigFile = ./nixos/work.nix;
        homeConfigFile = ./home-manager/work.nix;
      };
    };
  };
}
