#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
output_path="${1:-${repo_root}/data/homebrew-packages.nix}"

resolve_brew() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    echo /opt/homebrew/bin/brew
    return
  fi

  if [[ -x /usr/local/bin/brew ]]; then
    echo /usr/local/bin/brew
    return
  fi

  echo "brew_sync: Homebrew is not installed." >&2
  exit 1
}

brew_bin="$(resolve_brew)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/brew-sync.XXXXXX")"
tmp_brewfile="${tmp_dir}/Brewfile"
tmp_json="${tmp_dir}/installed.json"
tmp_leaves="${tmp_dir}/leaves"

cleanup() {
  rm -rf "${tmp_dir}"
}

trap cleanup EXIT

emit_from_bundle_dump() {
  HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1 \
    "${brew_bin}" bundle dump --force --describe --file "${tmp_brewfile}" >/dev/null

  python3 - <<'PY' "${tmp_brewfile}" "${output_path}"
import re
import sys
from pathlib import Path

brewfile_path = Path(sys.argv[1])
output_path = Path(sys.argv[2])

taps = []
brews = []
casks = []

patterns = {
    "tap": re.compile(r'^tap "([^"]+)"'),
    "brew": re.compile(r'^brew "([^"]+)"'),
    "cask": re.compile(r'^cask "([^"]+)"'),
}

for raw_line in brewfile_path.read_text().splitlines():
    line = raw_line.strip()
    if not line or line.startswith("#"):
        continue

    for kind, pattern in patterns.items():
        match = pattern.match(line)
        if not match:
            continue

        value = match.group(1)
        if kind == "tap":
            taps.append(value)
        elif kind == "brew":
            brews.append(value)
        elif kind == "cask":
            casks.append(value)
        break

def emit_list(name: str, values: list[str]) -> str:
    lines = [f"  {name} = ["]
    lines.extend(f'    "{value}"' for value in values)
    lines.append("  ];")
    return "\n".join(lines)

contents = "\n".join(
    [
        "{",
        "  # Managed by `brew_sync`. Review diffs before committing.",
        emit_list("taps", taps),
        "",
        emit_list("brews", brews),
        "",
        emit_list("casks", casks),
        "}",
        "",
    ]
)

output_path.write_text(contents)
PY
}

emit_from_live_queries() {
  "${brew_bin}" info --json=v2 --installed > "${tmp_json}"
  "${brew_bin}" leaves | LC_ALL=C sort -u > "${tmp_leaves}"

  python3 - <<'PY' "${tmp_json}" "${tmp_leaves}" "${output_path}"
import json
import sys
from pathlib import Path

json_path = Path(sys.argv[1])
leaves_path = Path(sys.argv[2])
output_path = Path(sys.argv[3])

data = json.loads(json_path.read_text())
leaves = {line.strip() for line in leaves_path.read_text().splitlines() if line.strip()}

formulae = set()
casks = set()
taps = set()

for formula in data.get("formulae", []):
    full_name = formula.get("full_name") or formula["name"]
    installed = formula.get("installed", [])
    explicitly_requested = any(item.get("installed_on_request") for item in installed)
    if explicitly_requested or full_name in leaves or formula["name"] in leaves:
        formulae.add(full_name)
        tap = formula.get("tap")
        if tap and tap != "homebrew/core":
            taps.add(tap)

for cask in data.get("casks", []):
    token = cask.get("full_token") or cask["token"]
    casks.add(token)
    tap = cask.get("tap")
    if tap and tap != "homebrew/cask":
        taps.add(tap)

def emit_list(name: str, values: set[str]) -> str:
    lines = [f"  {name} = ["]
    lines.extend(f'    "{value}"' for value in sorted(values))
    lines.append("  ];")
    return "\n".join(lines)

contents = "\n".join(
    [
        "{",
        "  # Managed by `brew_sync`. Review diffs before committing.",
        emit_list("taps", taps),
        "",
        emit_list("brews", formulae),
        "",
        emit_list("casks", casks),
        "}",
        "",
    ]
)

output_path.write_text(contents)
PY
}

mkdir -p "$(dirname "${output_path}")"
if ! emit_from_bundle_dump; then
  echo "brew_sync: brew bundle dump failed, falling back to installed package queries." >&2
  emit_from_live_queries
fi

echo "Updated ${output_path}"
echo "Next: review the diff, commit it, then run dm or nm to apply the Homebrew changes."
