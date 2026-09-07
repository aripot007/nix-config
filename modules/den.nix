{
  inputs,
  den,
  ...
}: {
  imports = [inputs.den.flakeModule];

  den.hosts.x86_64-linux.tartiflex.users.aristide = {};

  den.aspects.igloo = {
    includes = [den.batteries.hostname];
    nixos = {pkgs, ...}: {environment.systemPackages = [pkgs.hello];};
  };

  den.aspects.aristide = {
    includes = [den.batteries.define-user den.batteries.primary-user];
    homeManager = {pkgs, ...}: {
      home.stateVersion = "24.05";
      home.packages = [pkgs.vim];
    };
  };

  den.homes.x86_64-linux."aristide@tartiflex" = {
    # Home-manager requires 'pkgs' instance
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    extraSpecialArgs = {inherit inputs;};
    modules = [
      ../home.nix
      ../git.nix
      ../firefox.nix
      ../niri.nix
    ];
  };
}
