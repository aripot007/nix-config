{config, ...}: {
  sops = {
    defaultSopsFile = ./secrets/system.yaml;
    age.keyFile = "/persist/secrets/sops-key.txt";
    secrets."backups/repo_url" = {};
    secrets."backups/password" = {
      group = config.users.groups.backups.name;
      mode = "0440";
    };

    templates."remote-creds.toml" = {
      group = config.users.groups.backups.name;
      mode = "0440";

      content = ''
        [repository]
        repository = "${config.sops.placeholder."backups/repo_url"}"
        password-file = "${config.sops.secrets."backups/password".path}"
      '';
    };
  };
}
