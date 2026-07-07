{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-hardware = {
      url = "github:NixOs/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.home-manager.follows = "home-manager";
    opencode = {
      url = "github:anomalyco/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ self, nixos-hardware, disko, impermanence, nixpkgs, home-manager, opencode, ... }: {
    
    nixosConfigurations.tartiflex = nixpkgs.lib.nixosSystem {
      modules = [ 
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        nixos-hardware.nixosModules.framework-16-amd-ai-300-series
        ./disko-config.nix
        ./configuration.nix
        ./impermanence.nix
        {
          users.users.aristide = {
            isNormalUser = true;
            extraGroups = [ "wheel" "video" ];
            initialPassword = "password";
            packages = [ inputs.home-manager.packages."x86_64-linux".default ];
          };
        
          hardware.inputmodule.enable = true;
        }
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
