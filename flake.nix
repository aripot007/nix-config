{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
  };
  outputs = inputs@{ self, disko, impermanence, nixpkgs, ... }: {
    nixosConfigurations.tartiflex = nixpkgs.lib.nixosSystem {
      modules = [ 
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        ./disko-config.nix
        ./configuration.nix
        ./impermanence.nix
      ];
    };
  };
}
