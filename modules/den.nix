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
      home.packages = [pkgs.vim pkgs.cowsay];
    };
  };

  den.homes.x86_64-linux."aristide@tartiflex" = rec {
    # Home-manager requires 'pkgs' instance
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    extraSpecialArgs = {inherit inputs;};
    home.packages = [pkgs.lolcat];
  };
}
