# Omarchy Window Overview

A GNOME-style overview for Omarchy and Hyprland. It dims the desktop and lays
out open windows as live previews, grouped by monitor. Click a preview or use
the keyboard to switch to that window.

## Features

- A fullscreen overview on every connected monitor
- Windows grouped by the monitor they appear on
- Live previews provided by Hyprland’s Wayland toplevel export
- Mouse selection and keyboard navigation
- Configurable Hyprland shortcut, with Super as the default

## Requirements

- Omarchy’s Quickshell shell
- Hyprland with the `hyprland-toplevel-export-v1` protocol
- Quickshell 0.3 or later

The protocol is required for live window previews. Without it, the overview
cannot capture window contents.

## Install

Install the plugin through Omarchy:

```bash
omarchy plugin add https://github.com/sudo-make-jon/omarchy-overview.git --enable
~/.config/omarchy/plugins/jonathan.window-overview/configure.sh
```

The configurator asks for a shortcut and defaults to `SUPER`. It writes a
marked binding block to `~/.config/hypr/bindings.lua`, backs up that file, and
reloads Hyprland. To change the shortcut later, run the configurator again.
For example:

```bash
~/.config/omarchy/plugins/jonathan.window-overview/configure.sh --key 'SUPER + ALT + W'
```

You can also install from a local checkout with `./install.sh`. It copies the
plugin to Omarchy’s user plugin directory, enables it, and configures the
default Super shortcut when run without an interactive terminal.

## Use

Press and release **Super** to open the overview. Choose a window with the
mouse, or move the selection with the arrow keys and press Enter. Press Escape
to close the overview.

The Super binding triggers on key release. Hyprland can also trigger it when
Super is released after using Super with another shortcut. If you prefer to
avoid that, configure a chord such as `SUPER + ALT + W`.

## Remove

Remove the plugin with Omarchy:

```bash
omarchy plugin remove jonathan.window-overview
```

Then remove the block between the `BEGIN` and `END` comments for
`jonathan.window-overview` in `~/.config/hypr/bindings.lua` and reload Hyprland:

```bash
hyprctl reload
```

## Troubleshooting

- If the shortcut does nothing, check that its binding appears in
  `~/.config/hypr/bindings.lua` and that Hyprland has no config errors.
- If the overview opens without previews, check that your Hyprland build
  supports `hyprland-toplevel-export-v1`.
- To confirm Omarchy has enabled the plugin, run
  `omarchy plugin list` and look for `jonathan.window-overview`.

## Development

For a local checkout, validate the plugin manifest with:

```bash
omarchy plugin validate .
```

To load the overlay manually after copying it to
`~/.config/omarchy/plugins/jonathan.window-overview/`:

```bash
omarchy plugin enable jonathan.window-overview
omarchy-shell shell rescanPlugins
omarchy-shell shell summon jonathan.window-overview '{}'
```

## License

MIT. See [LICENSE](LICENSE).
