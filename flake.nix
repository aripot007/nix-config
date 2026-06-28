{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.home-manager.follows = "home-manager";
  };
  outputs = inputs@{ self, disko, impermanence, nixpkgs, home-manager, ... }: {
    
    nixosConfigurations.tartiflex = nixpkgs.lib.nixosSystem {
      modules = [ 
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        ./disko-config.nix
        ./configuration.nix
        ./impermanence.nix
      ];
    };

    homeConfigurations = {
      "aristide@tartiflex" = home-manager.lib.homeManagerConfiguration {
        # Home-manager requires 'pkgs' instance
        pkgs = nixpkgs.legacyPackages.x86_64-linux; 
        extraSpecialArgs = {inherit inputs;};
        modules = [
          ./home.nix
        ];
      };
    };
  };
}
