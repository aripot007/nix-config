{
  config,
  lib,
  pkgs,
  ...
}: {
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/logs".neededForBoot = true;

  boot.initrd.systemd.services.rollback = {
    description = "Rollback BTRFS root subvolume";
    wantedBy = ["initrd.target"];
    requires = [
      "dev-mapper-crypted.device"
    ];
    after = [
      "local-fs-pre.target"
      "dev-mapper-crypted.device"
    ];
    before = ["sysroot.mount"];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /mnt

      echo "Rolling back rootfs to blank state"
      
      # Create a snapshot of the dirty rootfs
      if [[ -e /mnt/@rootfs ]]; then
          mkdir -p /mnt/old_rootfs
          rootfs_date=$(date --date="@$(stat -c %Y /mnt/@rootfs)" "+%Y-%m-%d_%H-%M-%S")
          timestamp=$(date "+%s")
          btrfs subvolume snapshot -r /mnt/@rootfs "/mnt/old_rootfs/@''${rootfs_date}_$timestamp"
      fi

      # Recursively delete all nested subvolumes inside a subvolume snapshot
      delete_subvolume_recursively() {
          echo "Recursively deleting /$1 subvolume ..."
          btrfs subvolume list -o "/mnt/$1" |
          cut -f9 -d' ' |
          while read subvolume; do
              echo "+ Deleting /mnt/$subvolume subvolume ..."
              btrfs subvolume delete "/mnt/$subvolume"
          done &&
          echo "+ Deleting /mnt/$1 subvolume ..." &&
          btrfs subvolume delete "/mnt/$1"
      }

      echo "Restoring blank @rootfs ..."
      delete_subvolume_recursively "@rootfs"
      btrfs subvolume snapshot /mnt/@blank-rootfs /mnt/@rootfs

      echo "Cleaning up old rootfs backup snapshots ..."
      for i in $(find /mnt/old_rootfs/ -maxdepth 1 -mtime +15); do
          delete_subvolume_recursively "$i"
      done
      
      umount /mnt
    '';
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/etc/NetworkManager/system-connections"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  environment.persistence."/logs" = {
    hideMounts = true;
    directories = [
      "/var/log"
    ];
  };
}