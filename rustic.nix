{
  lib,
  config,
  pkgs,
  ...
}: {
  options.programs.rustic = {
    # repository = lib.mkOption {
    #   description = "Repository configuration";
    #   type = lib.types.nullOr (lib.types.attrsOf {
    #     repository = lib.mkOption {
    #       description = "The path to the repository";
    #       type = lib.types.str;
    #       example = "/tmp/rustic";
    #     };
    #     password-file = lib.mkOption {
    #       description = "Path to a file containing the password for the repository";
    #       type = lib.types.str;
    #     };
    #   });
    # };
    backups = lib.mkOption {
      description = "Backup configuration";
      type = lib.types.attrsOf (
        lib.types.submodule (
          {name, ...}: {
            options = {
              as-path = lib.mkOption {
                description = "Specifies the path for the backup when the source contains a single path.";
                type = with lib.types; nullOr str;
              };
              globs = lib.mkOption {
                description = "Array of globs specifying what to include/exclude in the backup.";
                type = with lib.types; nullOr (listOf str);
                example = [
                  "!.cache"
                  "!.cache/firefox"
                ];
              };
              glob-files = lib.mkOption {
                description = "Array of glob files specifying what to include/exclude in the backup.";
                type = with lib.types; nullOr (listOf str);
              };
              iglobs = lib.mkOption {
                description = "Like globs, but case insensitive";
                type = with lib.types; nullOr (listOf str);
              };
              iglob-files = lib.mkOption {
                description = "Array of case-insensitive glob files specifying what to include/exclude in the backup.";
                type = with lib.types; nullOr (listOf str);
              };
              host = lib.mkOption {
                description = "Host name used in the snapshot";
                type = lib.types.nullOr lib.types.str;
              };
              one-file-system = lib.mkOption {
                description = "If true, only backs up files from the same filesystem as the source.";
                type = lib.types.nullOr lib.types.bool;
              };
              git-ignore = lib.mkOption {
                description = "If true, use .gitignore rules to exclude files from the backup in the source directory.";
                type = lib.types.nullOr lib.types.bool;
              };

              # Snapshot-specific options
              sources = lib.mkOption {
                description = "Array of source directories or file(s) to back up.";
                type = with lib.types; nullOr (listOf str);
              };
              hooks = lib.mkOption {
                description = "Hooks to run before and after backing up the defined sources.";
                default = null;
                type = lib.types.nullOr (lib.types.submodule {
                  options = {
                    run-before = lib.mkOption {
                      description = "Run the given commands before execution";
                      type = with lib.types; nullOr (listOf str);
                    };
                    run-after = lib.mkOption {
                      description = "Run the given commands after successful execution";
                      type = with lib.types; nullOr (listOf str);
                    };
                    run-failed = lib.mkOption {
                      description = "Run the given commands after failed execution";
                      type = with lib.types; nullOr (listOf str);
                    };
                    run-finally = lib.mkOption {
                      description = "Run the given commands after every execution";
                      type = with lib.types; nullOr (listOf str);
                    };
                  };
                });
              };
            };
          }
        )
      );
    };
  };
  config = let
    toml = pkgs.formats.toml {};
  in {
    environment.etc =
      lib.mapAttrs' (
        name: backup_opt: let
          backup = lib.filterAttrsRecursive (n: v: v != null) backup_opt;
        in
          lib.nameValuePair "rustic/backup-${name}.toml" {
            source = toml.generate "backup-${name}.toml" {
              backup.snapshots = [
                (
                  {
                    name = name;
                  }
                  // backup
                )
              ];
            };
          }
      )
      config.programs.rustic.backups;
  };
}
