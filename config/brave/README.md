# Brave appearance

The active Brave interface theme is the public theme extension:

- ID: `fjofdcgahcnlkdjapcbeonbnmjdnfcki`
- Name: `Gruvbox Material Dark`
- Version: `1.0.0`

The sanitized manifest in `theme/manifest.json` contains only browser-interface
theme colors. No Brave profile, Preferences, Local State, cookies, history,
tokens, sessions, or private extension data is included.

Website-content theming was not identified as a separate active extension.

The repository contains only the sanitized public theme manifest. It does not
deploy or modify `~/.config/BraveSoftware`. To use it, open
`brave://extensions`, enable Developer mode, choose “Load unpacked”, and select
the repository's `config/brave/theme` directory. Do not copy a Brave profile.
