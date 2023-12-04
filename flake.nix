{
  description = "Jonathan Bowman nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # nixpkgs-wayland
    # nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;
  in {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    packages.x86_64-linux = import ./pkgs nixpkgs.legacyPackages.x86_64-linux;
    overlays = import ./overlays {inherit inputs;};
    # NixOS configuration entrypoint
    nixosConfigurations = {
			# Available through 'sudo nixos-rebuild switch --flake .#lappy386'
      lappy386 = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/lappy.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.bowmanjd = import ./home-manager/home.nix;
            home-manager.extraSpecialArgs = {inherit inputs outputs;};

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
			# Available through 'sudo nixos-rebuild switch --flake .#work'
      work = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/work.nix
          home-manager.nixosModules.home-manager
          {
            #home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jbowman = import ./home-manager/work.nix;
            home-manager.extraSpecialArgs = {inherit inputs outputs;};

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
    };

    # Standalone home-manager configuration entrypoint
    #homeConfigurations = {
		#	# Available through 'home-manager switch --flake .#bowmanjd@lappy386'
    #  "bowmanjd@lappy386" = home-manager.lib.homeManagerConfiguration {
    #    pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
    #    extraSpecialArgs = {inherit inputs outputs;};
    #    modules = [./home-manager/home.nix];
    #  };
		#	# Available through 'home-manager switch --flake .#jbowman@work'
    #  "jbowman@work" = home-manager.lib.homeManagerConfiguration {
    #    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    #    extraSpecialArgs = {inherit inputs outputs;};
    #    modules = [./home-manager/work.nix];
    #  };
    #};
  };
}
