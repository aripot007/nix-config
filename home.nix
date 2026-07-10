{
  config,
  pkgs,
  inputs,
  ...
}: let
  defaultWallpaper = "${pkgs.nixos-artwork.wallpapers.simple-dark-gray.gnomeFilePath}";
  dotfiles_dir = "${config.home.homeDirectory}/.config/nixos";
in {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "aristide";
  home.homeDirectory = "/home/aristide";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Prevent home-manager from trying to write in the out-of-store config files
    sideloadInitLua = true;

    extraPackages = with pkgs; [
      ripgrep
      fd
      gcc
      gnumake
      tree-sitter
      lua-language-server
      nil
      alejandra
      stylua
      shfmt
    ];
  };

  programs.lazygit.enable = true;
  programs.chromium.enable = true;

  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles_dir}/nvim";

  home.packages = with pkgs; [
    waybar
    swaylock
    # foot
    fuzzel
    # swaync
    # swayidle
    # grim
    # slurp
    # wl-clipboard
    # clipman
    # brightnessctl
    # alsa-utils
    # pulseaudio
    wob
    # inputs.opencode.packages.${pkgs.system}.default
  ];

  programs.kitty.enable = true;

  xdg.configFile."sway/config".text = ''
    exec {
        systemctl --user import-environment
        hash dbus-update-activation-environment 2>/dev/null && dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK
    }

    exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1

    set $WOBSOCK $XDG_RUNTIME_DIR/wob.sock
    exec sh -c 'rm -f "$WOBSOCK" && mkfifo "$WOBSOCK" && tail -f "$WOBSOCK" | wob'

    set $mod Mod4
    set $left h
    set $down j
    set $up k
    set $right l
    set $term foot
    set $menu fuzzel | xargs swaymsg exec --

    exec wl-paste -t text --watch clipman store --no-persist

    output "*" bg ${defaultWallpaper} fill

    exec swayidle -w \
             timeout 300 'swaylock -f -c 000000' \
             timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
             before-sleep 'swaylock -f -i ${defaultWallpaper} -u'

    input type:touchpad {
        dwt enabled
        tap enabled
        natural_scroll enabled
        middle_emulation enabled
    }

    input type:keyboard {
        xkb_layout "fr"
        xkb_variant "azerty"
        xkb_numlock enabled
        xkb_options compose:menu
    }

    input type:pointer {
        accel_profile "flat"
        pointer_accel -0.2
    }

    bindsym $mod+Return exec $term
    bindsym $mod+Shift+a kill
    bindsym $mod+d exec $menu
    floating_modifier $mod normal
    bindsym $mod+Shift+c reload
    bindsym $mod+Shift+e exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'

    bindsym $mod+$left focus left
    bindsym $mod+$down focus down
    bindsym $mod+$up focus up
    bindsym $mod+$right focus right
    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right

    bindsym $mod+Shift+$left move left
    bindsym $mod+Shift+$down move down
    bindsym $mod+Shift+$up move up
    bindsym $mod+Shift+$right move right
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

    bindsym $mod+ampersand workspace 1
    bindsym $mod+eacute workspace 2
    bindsym $mod+quotedbl workspace 3
    bindsym $mod+apostrophe workspace 4
    bindsym $mod+parenleft workspace 5
    bindsym $mod+minus workspace 6
    bindsym $mod+egrave workspace 7
    bindsym $mod+underscore workspace 8
    bindsym $mod+ccedilla workspace 9
    bindsym $mod+agrave workspace 10

    bindsym $mod+Shift+ampersand move container to workspace 1
    bindsym $mod+Shift+eacute move container to workspace 2
    bindsym $mod+Shift+quotedbl move container to workspace 3
    bindsym $mod+Shift+apostrophe move container to workspace 4
    bindsym $mod+Shift+parenleft move container to workspace 5
    bindsym $mod+Shift+minus move container to workspace 6
    bindsym $mod+Shift+egrave move container to workspace 7
    bindsym $mod+Shift+underscore move container to workspace 8
    bindsym $mod+Shift+ccedilla move container to workspace 9
    bindsym $mod+Shift+agrave move container to workspace 10

    bindsym $mod+b splith
    bindsym $mod+v splitv
    bindsym $mod+s layout stacking
    bindsym $mod+z layout tabbed
    bindsym $mod+e layout toggle split
    bindsym $mod+f fullscreen
    bindsym $mod+Shift+space floating toggle
    bindsym $mod+space focus mode_toggle
    bindsym $mod+a focus parent
    bindsym $mod+q focus child

    bindsym $mod+plus move scratchpad
    bindsym $mod+equal scratchpad show

    mode "resize" {
        bindsym $left resize shrink width 10px
        bindsym $down resize grow height 10px
        bindsym $up resize shrink height 10px
        bindsym $right resize grow width 10px

        bindsym Left resize shrink width 10px
        bindsym Down resize grow height 10px
        bindsym Up resize shrink height 10px
        bindsym Right resize grow width 10px

        bindsym Return mode "default"
        bindsym Escape mode "default"
        bindsym $mod+r mode "default"
    }
    bindsym $mod+r mode "resize"

    bar {
        swaybar_command waybar
    }

    include ~/.config/sway/config.d/*
  '';

  xdg.configFile."sway/config.d/10-audio-brightness-control.conf".text = ''
    bindsym XF86AudioRaiseVolume exec amixer set Master 5%+ | grep -P "\\[(\\d+)%\\]" -m 1 -o | sed "s/\[\|%\]//g" >> $WOBSOCK
    bindsym XF86AudioLowerVolume exec amixer set Master 5%- | grep -P "\\[(\\d+)%\\]" -m 1 -o | sed "s/\[\|%\]//g" >> $WOBSOCK
    bindsym XF86AudioMute exec bash -c 'if [ $(amixer set Master toggle | grep -P "\\[o(n|ff)\\]" -o -m 1 | cut -b3) == "f" ]; then echo 0; else echo $(amixer get Master | grep -P "\\[(\\d+)%\\]" -m 1 -o | sed "s/\[\|%\]//g"); fi >> $WOBSOCK'

    bindsym XF86MonBrightnessDown exec brightnessctl set 5%- | sed -En 's/.*\(([0-9]+)%\).*/\1/p' >> $WOBSOCK
    bindsym XF86MonBrightnessUp exec brightnessctl set +5% | sed -En 's/.*\(([0-9]+)%\).*/\1/p' >> $WOBSOCK

    bindsym XF86KbdBrightnessUp exec brightnessctl -d "asus::kbd_backlight" set 33%+ | sed -En 's/.*\(([0-9]+)%\).*/\1/p' >> $WOBSOCK
    bindsym XF86KbdBrightnessDown exec brightnessctl -d "asus::kbd_backlight" set 33%- | sed -En 's/.*\(([0-9]+)%\).*/\1/p' >> $WOBSOCK

    bindsym XF86AudioMicMute exec pactl set-source-mute 237 toggle
  '';

  xdg.configFile."sway/config.d/15-window-rules.conf".text = ''
    for_window [class="Extension: \(Bitwarden Password Manager\).*"] floating enable
  '';

  xdg.configFile."sway/config.d/20-bg-control.conf".text = ''
    # Custom wallpaper switching removed.
    # The default NixOS wallpaper is set in the main sway config.
  '';

  xdg.configFile."sway/config.d/20-power-control.conf".text = ''
    mode "power" {
      bindsym XF86PowerOff mode "default"
      bindsym Escape mode "default"
      bindsym Return mode "default"

      bindsym $mod+Shift+r mode "default"; exec systemctl reboot
      bindsym $mod+Shift+s mode "default"; exec systemctl poweroff
      bindsym $mod+Control+r mode "default"; exec systemctl soft-reboot

      bindsym $mod+Shift+l mode "default"; exec swaylock -f -c 000000
      bindsym $mod+Control+Shift+l mode "default"; exec swaylock -f -i ${defaultWallpaper} -u
      bindsym $mod+Control+l mode "default"; exec swaylock -f -c 00000000
      bindsym $mod+Alt+l mode "default"; exec swaylock -f -i ${defaultWallpaper} -u

      bindsym $mod+Shift+v mode "default"; exec swaylock -f -c 000000; exec systemctl suspend
      bindsym $mod+Shift+u mode "default"; exec systemctl reboot --firmware-setup
    }

    bindsym XF86PowerOff mode "power"
  '';

  xdg.configFile."sway/config.d/20-workspace-rules.conf".text = ''

    # Workspace 2 - Code editors
    assign [class="(VSCodium|VisUAL2|jetbrains-pycharm|jetbrains-studio)"] 2

    # Workspace 3 - Web Browsers
    assign [app_id="(chromium|firefox-esr)"] 3
    assign [class="(Firefox-esr|Chromium)"] 3

    # Workspace 4 - Communication stuff / chat
    assign [app_id="(^thunderbird$|telegram|discord|TelegramDesktop)"] 4
    assign [class="obsidian"] 4


    # Benchmarks
    assign [title="^glmark2*"] 9
  '';

  xdg.configFile."sway/config.d/30-theme.conf".text = ''
    smart_borders on
    smart_gaps on

    gaps inner 3

    client.focused #51F077E6 #51F077E6 #2A2A2A #AE00FF
    client.unfocused #333333E6 #222222E6 #B5B5B5
    client.focused_inactive #333333E6 #5F676AE6 #FFFFFF
    client.urgent #2F343AE6 #900000E6 #FFFFFF

    set $gnome-schema org.gnome.desktop.interface

    exec_always {
      gsettings set $gnome-schema gtk-theme 'Adwaita-dark'
    }
  '';

  xdg.configFile."sway/config.d/35-screenshot.conf".text = ''
    bindsym Print exec grim -g "$(slurp -d)" - | wl-copy -t image/png
    bindsym Mod4+Shift+S exec grim -g "$(slurp -d)" - | wl-copy -t image/png
  '';

  xdg.configFile."sway/config.d/40-japanese-input.conf".text = ''
    # set -x GTK_IM_MODULE 'fcitx'
    # set -x QT_IM_MODULE 'fcitx'
    # set -x XMODIFIERS '@im=fcitx'
    # exec_always fcitx5 -d --replace
  '';

  xdg.configFile."sway/config.d/50-systemd-user.conf".text = ''
    exec systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP
    exec hash dbus-update-activation-environment 2>/dev/null && \
         dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_CURRENT_DESKTOP=sway
  '';

  xdg.configFile."sway/config.d/55-notifications.conf".text = ''
    exec swaync

    # Toggle control center
    bindsym $mod+Shift+n exec swaync-client -t -sw
  '';

  xdg.configFile."sway/config.d/80-transparency.conf".text = ''
    set $opacity 0.9
    for_window [class="Firefox-esr"] opacity $opacity
  '';
}
