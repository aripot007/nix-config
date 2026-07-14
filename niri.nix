{pkgs, ...}: {
  home.packages = with pkgs; [
    niri
    xwayland-satellite
  ];

  xdg.configFile."niri/config.kdl" = {
    source = pkgs.replaceVars ./niri.kdl {
      DEFAULT_AUDIO_SINK = null;
      DEFAULT_AUDIO_SOURCE = null;
    };
  };
}
