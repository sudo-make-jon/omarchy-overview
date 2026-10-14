#!/usr/bin/env bash
set -euo pipefail

readonly plugin_id="jonathan.window-overview"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
plugin_dir="$config_home/omarchy/plugins/$plugin_id"

mkdir -p "$plugin_dir"
install -m 0644 "$script_dir/manifest.json" "$plugin_dir/manifest.json"
install -m 0644 "$script_dir/WindowOverview.qml" "$plugin_dir/WindowOverview.qml"
install -m 0755 "$script_dir/configure.sh" "$plugin_dir/configure.sh"

if [[ -t 0 ]]; then
  "$script_dir/configure.sh"
else
  "$script_dir/configure.sh" --key SUPER
fi
omarchy plugin enable "$plugin_id"
omarchy-shell shell rescanPlugins

printf '\nWindow Overview is installed. Use your configured shortcut to open it.\n'
