# Installation

Format disks :

```sh
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount ./disko-config.nix
```

Install nixos :
```sh
sudo nixos-install --flake .#<host-name>
```
