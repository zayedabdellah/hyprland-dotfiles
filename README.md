# Dotfiles

This repository contains a portable snapshot of the active desktop rice. The
active configuration is the source of truth; backups, generated state, private
profiles, browser profiles, and game content are intentionally excluded.

The Hyprland configuration is modular Lua and keeps the active keybinds,
startup commands, window rules, workspace behavior, Waybar actions, scripts,
and appearance values intact.

## Prerequisites

This script assumes you already have Hyprland installed and running. It will check for other necessary components and provide installation suggestions if they are missing. However, it is crucial that Hyprland itself is already operational.

## Machine profiles

The current laptop is represented by the exact first-class profile:

```text
config/hypr/profiles/zayed-laptop.lua
  eDP-1 / 2560x1600@165 / position 0x0 / scale 2
```

`config/hypr/profiles/generic.lua` is the safe fallback. The laptop profile is
never selected implicitly: choose it explicitly with
`DOTFILES_MACHINE_PROFILE=zayed-laptop` or an ignored
`config/hypr/machine.local.lua` based on
`config/hypr/machine.local.lua.example`. Invalid profile names stop with a
clear error.

Waybar receives the selected profile's `DOTFILES_NETWORK_INTERFACE`. The
laptop retains `wlp3s0`; generic systems use the active route interface or
Waybar's own automatic selection.

## Installation

To set up these dotfiles, follow these steps:

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/zayedabdellah/dotfiles.git
    cd dotfiles
    ```

2.  **Run the installation script:**

    The `install.sh` script will:
    *   Check the current system for required applications (e.g., `kitty`,
        `waybar`, `rofi`, `grim`, `slurp`, `brightnessctl`, `playerctl`,
        `swaync`, `awww-daemon`, `hyprpolkitagent`, `hyprshutdown`).
    *   Copy the approved core configuration to its XDG destination, including
        hidden files.
    *   Copy the approved configuration, theme, cursor, font, wallpaper, and
        script assets to their corresponding XDG locations.

    ```bash
    chmod +x install.sh
    ./install.sh --profile generic
    ```

The installer chooses `generic` safely when no profile is specified in
non-interactive mode. Interactive installs detect the laptop only when
`eDP-1`, `2560x1600@165`, and NVIDIA characteristics all match, then ask for
confirmation. Use `--profile zayed-laptop` for the exact laptop profile.

Optional modules are disabled unless explicitly requested with
`--enable-optional MODULE`. Use `--audit` or `--dry-run` to inspect planned
actions without downloads, package changes, shell changes, desktop settings,
or configuration deployment. Fish becomes the login shell only with the
explicit `--set-default-shell` option and interactive confirmation.
GTK desktop settings are applied only with `--apply-desktop-settings`.

Gentoo and Arch are the supported package-management targets. Gentoo uses
verified Portage atoms only and prints USE-flag/overlay guidance without
changing Portage configuration. Fedora support is experimental and performs
no automatic package installation. NixOS requires a future native
NixOS/Home Manager module; this shell installer does not manage NixOS
packages declaratively.

3.  **Restart Hyprland:**

    After the script completes, restart your Hyprland session to apply the new configurations.

## Configuration Details

### Hyprland

The Hyprland configuration is located in `~/.config/hypr/`. It uses a modular Lua setup, with `hyprland.lua` requiring various modules from the `modules/` directory for different aspects like keybinds, autostart, decorations, and more.

### Waybar

The Waybar configuration is located in `~/.config/waybar/`. It includes `config.jsonc` for the main bar layout and `style.css` for styling. Custom scripts used by Waybar are found in `scripts/`.

### Themes

GTK, Qt/Kvantum, cursor, browser-interface theme, font, and wallpaper assets
are included under `themes/`, `icons/`, `config/brave/`, `fonts/`, and
`config/hypr/`. The confirmed Torii image is included at
`config/hypr/wallpapers/torii.jpg`; the Hyprlock wrapper still uses a
screenshot fallback when the image is unavailable.

#### Theme Setup Instructions

To ensure your apps pick up the themes correctly:
1.  **GTK Apps:** The script attempts to set the theme automatically. You can verify this by opening `nwg-look`.
2.  **Qt Apps:** 
    *   Open **Kvantum Manager**.
    *   Go to **Change/Delete Theme**.
    *   Select **gruvbox-kvantum** from the list and click **Use this theme**
        when the exact active theme files have been supplied with verified
        redistribution permission. The repository preserves this active
        selector but does not silently substitute another Kvantum theme while
        the asset license is unresolved.
    *   Open **qt6ct** (or `qt5ct` if using Qt5) and ensure the **Style** is set to **kvantum**.

If you have legal permission to use the active local Gruvbox Kvantum theme,
manually copy its two files into both
`~/.config/Kvantum/gruvbox-kvantum/` and `~/.themes/gruvbox-kvantum/`.
The installer intentionally does not bundle or copy those unverified files.

## Dependencies

The following applications are used in these configurations:

*   **Hyprland**: The Wayland compositor itself.
*   **Waybar**: A highly customizable Wayland bar.
*   **kitty**: A fast, feature-rich, GPU based terminal emulator.
*   **Thunar**: A fast and easy to use file manager.
*   **Rofi**: A window switcher, application launcher, and dmenu replacement.
*   **Brave Browser**: A privacy-focused web browser.
*   **hyprshutdown**: A graceful shutdown utility for Hyprland.
*   **hyprlock**: A screen locker for Hyprland.
*   **grim**: A screenshot utility for Wayland.
*   **slurp**: A utility to select a region on a Wayland compositor.
*   **wl-clipboard**: Command-line copy/paste utilities for Wayland.
*   **PipeWire**: A server for handling audio and video streams.
*   **brightnessctl**: A utility to control screen brightness.
*   **playerctl**: A command-line utility to control media players.
*   **swaync**: A Wayland native notification daemon.
*   **awww-daemon**: An animated wallpaper daemon for Wayland.
*   **hyprpolkitagent**: A Polkit agent for Hyprland.
*   **nwg-look**: A GTK3 settings editor for wlroots-based compositors.
*   **Kvantum**: A SVG-based theme engine for Qt.
*   **qt6ct**: Qt6 Configuration Tool.
*   **fish**: A smart and user-friendly command line shell.
*   **Papirus-Dark**: Required icon theme for GTK, Qt, and xsettingsd.

Rofi preserves Oranchelo as the preferred icon theme without bundling it. The
Rofi launcher detects Oranchelo and falls back to the required Papirus-Dark
theme when Oranchelo is unavailable. If neither theme is installed, Rofi still
starts with its default icon behavior.

## Optional modules

RetroArch appearance settings, Sunshine, Dolphin Emulator, Suyu, GOverlay,
vkBasalt, vkSumi, Pavucontrol preferences, and `mimeapps.list` are stored
under `config/optional/` and are not part of the default rice deployment.
ROMs, BIOS files, saves, states, downloaded cores, thumbnails, logs, caches,
private emulator paths, and complete Brave profiles are not included.

## Compatibility workaround

The unsafe `xhost +SI:localuser:root` command is not part of the default
autostart. Only if a specific legacy X11 application requires root access,
apply that command manually for the duration of that session and remove the
access afterward. It is not installed or automated by this repository.

## Contributing

Feel free to fork this repository and adapt the configurations to your needs. If you have improvements or suggestions, please open an issue or submit a pull request.
