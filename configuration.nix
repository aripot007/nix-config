{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  security.sudo.extraConfig = "Defaults lecture = never";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Wifi support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "tartiflex";
  networking.networkmanager.enable = true;

  time.timeZone = "Canada/Eastern";

  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  security.polkit.enable = true;
  security.pam.services.swaylock = {};

  programs.sway.enable = true;

  # Configure keymaps
  console.keyMap = "fr";
  services.xserver.xkb.layout = "fr";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Touchpad support
  # services.libinput.enable = true;

  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      antialias = true;
      hinting.enable = true;
      hinting.autohint = true;
    };
    packages = with pkgs; [
      nerd-fonts.symbols-only
      nerd-fonts.jetbrains-mono
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  system.stateVersion = "25.11";
}
