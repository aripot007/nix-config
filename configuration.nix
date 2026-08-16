{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./backups.nix
  ];

  security.sudo.extraConfig = "Defaults lecture = never";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # # nix.gc = {
  # #   automatic = true;
  # #   dates = [
  # #     "weekly"
  # #   ];
  # #   persistent = true;
  # #   options = [];
  # # };

  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
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

  # Tailscale

  services.tailscale = {
    enable = true;
  };

  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    # Always allow traffic from your Tailscale network
    trustedInterfaces = [config.services.tailscale.interfaceName];
    # Allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [config.services.tailscale.port];
  };

  # Force tailscaled to use nftables (Critical for clean nftables-only systems)
  # This avoids the "iptables-compat" translation layer issues.
  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];

  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;

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
    steam-run
    (import inputs.creamlinux-installer {inherit pkgs;})
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };
  programs.gamemode.enable = true;

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-unwrapped"
    ];

  system.stateVersion = "25.11";
}
