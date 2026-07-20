# Oh My Posh theme

`torii-zayed.omp.json` is the exact active Fish theme. The installer deploys
it to `~/.themes/torii-zayed.omp.json`, which is the path used by the active
Fish initialization command.

The Oh My Posh executable is not vendored. The installer uses the official
upstream installer for non-NixOS systems, pins the known active-compatible
release `v29.31.1`, and keeps the executable in `~/.local/bin`. The official
installer interface does not expose a separate checksum parameter, so the
release pin is the current reproducibility control; a future release artifact
checksum can be added when the upstream process makes one practical.
