# Compatibility notes

The default Hyprland autostart does not grant root access to XWayland.

If a specific legacy X11 application has an independently verified need for
root access, a user may manually run the following for that session only:

```sh
xhost +SI:localuser:root
```

This command is intentionally not automated by the repository. Remove the
access afterward with the appropriate X server command for that session.

## Distribution support

Arch is the immediate full-install target. Gentoo remains a primary target,
but the installer only passes verified Gentoo `category/package` atoms to
Portage and never adds overlays, keywords, masks, licenses, or USE flags
automatically. If a required Hypr ecosystem atom is not verified, deployment
stops before files are copied and the required manual review is printed.

Verified Gentoo examples used by the installer include:

```text
gui-wm/hyprland
gui-apps/waybar
app-emulation/kitty
app-shells/fish
xfce-base/thunar
gui-apps/grim
gui-apps/slurp
gui-apps/wl-clipboard
sys-power/brightnessctl
media-sound/playerctl
x11-themes/kvantum
gui-apps/qt6ct
net-misc/networkmanager
app-misc/btop
```

Waybar commonly needs `network`, `wifi`, `tray`, `mpris`, `pipewire`,
`pulseaudio`, and `upower` USE support. Hyprland versions newer than the
verified main-repository ebuild may require `hyproverlay`; this repository
only prints that guidance and never enables it.

Fedora/Nobara support is experimental and incomplete. This installer does not
run `dnf` or `dnf5` automatically; the full Arch package path is not claimed
for Fedora and external repository coverage is not verified.

NixOS support is experimental and incomplete. Use a future Nix flake and
Home Manager/NixOS module for Fish, Oh My Posh, packages, and configuration;
this shell installer does not replace declarative system configuration.

## Kvantum local dependency

The active selector remains `gruvbox-kvantum`. The exact local test payload is
kept under `themes/kvantum/gruvbox-kvantum/` because the owner authorized this
repository test. Its source metadata names Sourav Gope, but a redistribution
license is still unverified; review before publishing. Deployment copies
`gruvbox-kvantum.kvconfig` and `gruvbox-kvantum.svg` into both:

```text
~/.config/Kvantum/gruvbox-kvantum/
~/.themes/gruvbox-kvantum/
```

Without those files, exact fresh-install Kvantum visual parity is unavailable;
the installer warns and continues without substituting another theme.

Optional emulator, overlay, streaming, and MIME modules are disabled by
default. Arch official packages are installed only when explicitly enabled;
AUR modules require an existing helper and a separate confirmation. Their
hardware-specific choices must still be reviewed manually before enabling
them.
