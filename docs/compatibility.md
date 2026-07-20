# Compatibility notes

The default Hyprland autostart does not grant root access to XWayland.

If a specific legacy X11 application has an independently verified need for
root access, a user may manually run the following for that session only:

```sh
xhost +SI:localuser:root
```

This command is intentionally not automated by the repository. Remove the
access afterward with the appropriate X server command for that session.
