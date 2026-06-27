{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                settings.allowDiscards = true; # Enables SSD TRIM
                content = {
                  type = "lvm_pv";
                  vg = "vg0";
                };
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      vg0 = {
        type = "lvm_vg";
        lvs = {
          swap = {
            size = "32G";
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };
          # Root BTRFS volume
          system = {
            size = "1T"; # Combined space for root, nix, home, and persist
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              # Create a blank snapshot of the root volume
              postCreateHook = ''
                MNTPOINT=$(mktemp -d)
                mount "/dev/mapper/vg0-system" "$MNTPOINT" -o subvol=/
                trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
                btrfs subvolume snapshot -r $MNTPOINT/@rootfs $MNTPOINT/@blank-rootfs
              '';
              subvolumes = {
                "@rootfs" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd:1" "noatime" ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd:1" "noatime" ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd:1" ];
                };
                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = [ "compress=zstd:1" "noatime" ];
                };
                # Separate subvolume for logs, excluded from backups
                "@logs" = {
                  mountpoint = "/logs";
                  mountOptions = [ "compress=zstd" "noatime" "noexec" "nosuid" "nodev" ];
                };
              };
            };
          };
          # Ext4 partition for VMs / docker containers
          ext4 = {
            size = "100G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/ext4";
            };
          };
        };
      };
    };
  };
}