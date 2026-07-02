# Hyprland Dotfiles

This repository contains my personal Hyprland and Waybar configurations, along with an installation script to help set them up on your system. The configurations are primarily written in Lua for Hyprland, leveraging its native Lua scripting capabilities.

## Prerequisites

This script assumes you already have Hyprland installed and running. It will check for other necessary components and provide installation suggestions if they are missing. However, it is crucial that Hyprland itself is already operational.

## Installation

To set up these dotfiles, follow these steps:

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/YOUR_USERNAME/hyprland-dotfiles.git
    cd hyprland-dotfiles
    ```

2.  **Run the installation script:**

    The `install.sh` script will:
    *   Detect your Linux distribution.
    *   Check for required applications (e.g., `kitty`, `waybar`, `rofi`, `grim`, `slurp`, `brightnessctl`, `playerctl`, `swaync`, `awww-daemon`, `hyprpolkitagent`, `hyprshutdown`).
    *   If any applications are missing, it will provide copy-paste commands for common distributions (Arch, Debian, Ubuntu, Fedora, Gentoo) to install them. You will be prompted to install them manually or continue without them.
    *   Copy the Hyprland and Waybar configuration files to `~/.config/hypr` and `~/.config/waybar` respectively.
    *   Copy the theme files to `~/.themes`.

    ```bash
    chmod +x install.sh
    ./install.sh
    ```

    **Important for Gentoo users:** If you are on Gentoo, the script will remind you to enable `hyproverlay` and accept keywords for the packages before running the `emerge` command.

3.  **Restart Hyprland:**

    After the script completes, restart your Hyprland session to apply the new configurations.

## Configuration Details

### Hyprland

The Hyprland configuration is located in `~/.config/hypr/`. It uses a modular Lua setup, with `hyprland.lua` requiring various modules from the `modules/` directory for different aspects like keybinds, autostart, decorations, and more.

### Waybar

The Waybar configuration is located in `~/.config/waybar/`. It includes `config.jsonc` for the main bar layout and `style.css` for styling. Custom scripts used by Waybar are found in `scripts/`.

### Themes

Theme files (GTK, Qt Kvantum) are included and will be placed in `~/.themes/` by the installation script.

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

## Contributing

Feel free to fork this repository and adapt the configurations to your needs. If you have improvements or suggestions, please open an issue or submit a pull request.
