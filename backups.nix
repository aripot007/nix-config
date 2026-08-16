{
  pkgs,
  config,
  lib,
  ...
}: let
  btrfs_device = "/dev/mapper/vg0-system";
  mount_dir = "/tmp/btrfs-backups/subvolumes";
  snapshots_dir = "${mount_dir}/rustic-backup-snapshots";
  subvol_root = name: "${snapshots_dir}/${name}";
  prepare_btrfs = pkgs.writeShellApplication {
    name = "prepare_btrfs_backup";
    runtimeInputs = [pkgs.btrfs-progs pkgs.mount pkgs.e2fsprogs];
    text = ''
      echo "Preparing BTRFS backups ..."

      mkdir -p "${mount_dir}"

      mount -o subvol=/ ${btrfs_device} ${mount_dir}

      mkdir -p "${snapshots_dir}"

      prepare_subvolume() {
        echo "Preparing $1 subvolume"
        local snapshot_dir
        snapshot_dir="${snapshots_dir}/$1"

        if [[ -e "$snapshot_dir" ]]; then
          echo "Deleting previous snapshot $snapshot_dir"
          btrfs subvolume delete "$snapshot_dir"
        fi

        btrfs subvolume snapshot -r "${mount_dir}/$1" "$snapshot_dir"

        # Save attributes
        pushd "${snapshots_dir}"
        lsattr -Ra "$1" 2>/dev/null | sed -E '/^\S+:$/d; /^\s*$/d; /\/\.\.?$/d; /^-+\s/d' > "$1.attributes"
        popd
        echo "Finished preparing $1 subvolume"
      }

      prepare_subvolume "@persist"

      prepare_subvolume "@home"
    '';
  };

  cleanup_btrfs = pkgs.writeShellApplication {
    name = "cleanup_btrfs_backup";
    runtimeInputs = [pkgs.btrfs-progs pkgs.umount pkgs.busybox];
    text = ''
      echo "Cleaning up BTRFS backups ..."

      cleanup_subvolume() {
        local snapshot_dir
        snapshot_dir="${snapshots_dir}/$1"

        if [[ -e "$snapshot_dir" ]]; then
          btrfs subvolume delete "$snapshot_dir"
        fi

        rm -fv "''${snapshot_dir}.attributes";
      }

      cleanup_subvolume "@persist"

      cleanup_subvolume "@home"


      [ -d "${snapshots_dir}" ] && rmdir -v "${snapshots_dir}";

      if [[ -d "${mount_dir}" ]]; then
        umount -v "${mount_dir}"
      fi
    '';
  };
in {
  environment.systemPackages = with pkgs; [
    rustic
  ];

  environment.etc."rustic/repo.toml" = {
    source = config.sops.templates."remote-creds.toml".path;
  };

  programs.rustic.backups = {
    btrfs = let
      prepend_root = subvol: let
        root = subvol_root subvol;
      in
        map (
          s:
            if lib.strings.hasPrefix "!" s
            then "!${root}" + (builtins.substring 1 (builtins.stringLength s) s)
            else root + s
        );
    in {
      as-path = "/btrfs/";
      sources = [snapshots_dir];
      hooks = {
        run-before = ["${prepare_btrfs}/bin/prepare_btrfs_backup"];
        run-finally = ["${cleanup_btrfs}/bin/cleanup_btrfs_backup"];
      };

      globs =
        ["*"]
        ++ prepend_root "@home/aristide" [
          "!/.cache/"
          "!/.npm"
          "!/.nix-defexpr"
          "!/.nix-profile"
          "!/.local/state"
          "!/.bash_history-*.tmp"
          "!/.local/share/flatpak"

          # .config: ignore everything by default (since most of it is managed by home-manager)
          "!/.config/*"
          "/.config/nixos" # nixos config repo
          "/.config/user-dirs.*" # xdg user dirs
          "/.config/dconf"
          "/.config/gtk-*/"
          "/.config/mimeapps.list" # XDG mime application mapping
          "/.config/monitors.xml"
          "/.config/eddie"
          "/.config/tailscale"

          # Chromium keeps lots of trash in the .config folder
          "!/.config/chromium/*"
          "/.config/chromium/Default" # profile
          "/.config/chromium/Local State" # global settings, encryption key state

          # Firefox
          "/.config/mozilla/firefox"
          "!/.config/mozilla/firefox/Crash Reports"

          # nvim
          "!/.local/share/nvim/lazy/"
          "!/.local/share/nvim/mason/"
          "!/.local/share/nvim/site/"

          # Steam
          "!/.local/share/Steam/*"
          "/.local/share/Steam/steamapps/compatdata/"
          "!/.steam/"
          "!/.steampid"
          "!/.steampath"

          # Steam games
          "/.config/unity3d" # Overcooked
        ];
    };
  };

  # systemd.services."backups" = {
  #   restartIfChanged = false;
  #   wants = ["network-online.target"];
  #   after = ["network-online.target"];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     RuntimeDirectory = "rustic-backups";
  #     CacheDirectory = "rustic-backups";
  #     CacheDirectoryMode = "0700";
  #     PrivateTmp = true;
  #     ExecStart = [
  #     ];
  #   };
  # };

  # services.restic.backups = let
  # in {
  #   test = {
  #     initialize = true;
  #     repositoryFile = "${config.sops.secrets."backups/repo_url".path}";
  #     passwordFile = "${config.sops.secrets."backups/password".path}";
  #     backupPrepareCommand = "${btrfs_prepare}/bin/prepare_btrfs_backup";
  #     paths = map (p: "/tmp/btrfs-backups/@persist${p}") [
  #       "/etc/machine-id"
  #     ];
  #   };
  # };
}
