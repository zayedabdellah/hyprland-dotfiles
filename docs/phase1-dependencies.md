# Phase 1 visual dependencies

This is a portability record, not the final multi-distribution package
installer. Package installation remains a later phase.

| Feature | Required dependency | Current repository use | Portability note |
| --- | --- | --- | --- |
| GTK, Qt, and xsettingsd icons | `Papirus-Dark` icon theme | Referenced by GTK 3/4, Qt6ct, and xsettingsd | Required. On Arch the package is commonly `papirus-icon-theme`; Gentoo and Fedora package names must be resolved by the later distro mapping. |
| Rofi application icons | `Oranchelo` preferred, `Papirus-Dark` fallback | `config/rofi/config.rasi` preserves Oranchelo; `config/rofi/launch.sh` detects it at runtime | Oranchelo is not bundled or redistributed. If unavailable, the wrapper passes `-icon-theme Papirus-Dark`; if both are absent, Rofi still starts with its default icon behavior. |
| Qt widget style | `kvantum-dark` | Selected by Qt6ct and `config/Kvantum/kvantum.kvconfig` | The repository no longer bundles the unlicensed Gruvbox Kvantum theme. |
| MPV subtitles | `JetBrains Mono` | Bundled under the repository's font payload | Replaces the unverified Google Sans font and removes the missing MPV font directory reference. |

The installer checks for Papirus-Dark but does not install it outside its
existing package-management behavior. Oranchelo remains the preferred visual
choice without being bundled; runtime fallback is automatic and documented.
