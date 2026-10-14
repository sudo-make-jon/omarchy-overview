#!/usr/bin/env bash
set -euo pipefail

readonly plugin_id="jonathan.window-overview"
readonly start_marker="-- BEGIN jonathan.window-overview managed binding"
readonly end_marker="-- END jonathan.window-overview managed binding"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
bindings_file="$config_home/hypr/bindings.lua"

usage() {
  cat <<'EOF'
Usage: ./configure.sh [--key SUPER | --key 'SUPER + SHIFT + TAB']

With no argument, asks for a Hyprland shortcut interactively. The selected
shortcut is written as a managed block in ~/.config/hypr/bindings.lua.
EOF
}

key=""
case "${1:-}" in
  --key)
    [[ $# -eq 2 ]] || { usage >&2; exit 2; }
    key="$2"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  "")
    read -r -p "Overview shortcut [SUPER]: " key
    key="${key:-SUPER}"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

key="$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]' | sed -E 's/[[:space:]]*\+[[:space:]]*/ + /g; s/^ +//; s/ +$//')"
if [[ ! "$key" =~ ^[A-Z0-9_:+\ -]+$ ]]; then
  printf 'Unsupported shortcut syntax: %s\nUse Hyprland names such as SUPER + W or SUPER + SHIFT + TAB.\n' "$key" >&2
  exit 2
fi
if [[ ! -f "$bindings_file" ]]; then
  printf 'Hyprland bindings file not found: %s\n' "$bindings_file" >&2
  exit 1
fi

python3 - "$bindings_file" "$key" "$start_marker" "$end_marker" <<'PY'
from pathlib import Path
import shutil
import sys
import time

path = Path(sys.argv[1])
key, start, end = sys.argv[2:]
text = path.read_text()
start_count = text.count(start)
end_count = text.count(end)
if start_count != end_count or start_count > 1:
    raise SystemExit("Managed overview binding markers are mismatched or duplicated; edit bindings.lua manually.")

command = "omarchy-shell shell toggle jonathan.window-overview '{}'"
parts = [part.strip() for part in key.split("+")]
if any(not part for part in parts):
    raise SystemExit("Shortcut contains an empty key or modifier.")
if key == "SUPER":
    binding = (
        f'o.bind("SUPER + SUPER_L", "Window overview", "{command}", {{ release = true }})\n'
        f'o.bind("SUPER + SUPER_R", "Window overview", "{command}", {{ release = true }})'
    )
else:
    binding = f'o.bind("{key}", "Window overview", "{command}")'
block = f"{start}\n{binding}\n{end}"
if start_count:
    begin = text.index(start)
    finish = text.index(end, begin) + len(end)
    updated = text[:begin] + block + text[finish:]
else:
    updated = text.rstrip() + "\n\n" + block + "\n"

backup = path.with_name(path.name + f".bak.{time.time_ns()}")
shutil.copy2(path, backup)
path.write_text(updated)
print(f"Configured Window Overview on {key}")
print(f"Backup: {backup}")
PY

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload
  hyprctl configerrors
fi
