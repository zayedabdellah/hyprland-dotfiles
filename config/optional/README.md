# Optional modules

These modules are not part of the default rice deployment. The Phase 1
installer only deploys one when it is explicitly requested with
`--enable-optional MODULE`.

- RetroArch appearance only
- Sunshine
- Dolphin Emulator
- Suyu
- GOverlay
- vkBasalt
- vkSumi
- Pavucontrol preferences
- mimeapps.list

Private, generated, copyrighted game content and machine-specific paths were
excluded. Template files are documentation inputs only and are never copied
without explicit, module-specific processing.

Deployment targets:

- `retroarch` -> `~/.config/retroarch/appearance.cfg`
- `sunshine` -> `~/.config/sunshine/apps.json`
- `dolphin-emu` -> `~/.config/dolphin-emu/appearance.ini` and its desktop entry
- `suyu` -> `~/.config/suyu/appearance.ini`
- `goverlay` -> `~/.config/goverlay/goverlay.conf`
- `vkBasalt` -> `~/.config/vkBasalt/vkBasalt.conf`
- `vkSumi` -> `~/.config/vkSumi/vkSumi.conf`
- `mimeapps` -> `~/.config/mimeapps.list`

Sunshine image assets are intentionally not referenced or invented. Pavucontrol
has no reusable preference file in the audited source.
