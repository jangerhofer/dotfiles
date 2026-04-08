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
tmp_json="${tmp_dir}/installed.json"
tmp_leaves="${tmp_dir}/leaves"

cleanup() {
  rm -rf "${tmp_dir}"
}

trap cleanup EXIT

"${brew_bin}" info --json=v2 --installed > "${tmp_json}"
"${brew_bin}" leaves | LC_ALL=C sort -u > "${tmp_leaves}"

mkdir -p "$(dirname "${output_path}")"
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

echo "Updated ${output_path}"
echo "Next: review the diff, commit it, then run dm or nm to apply the Homebrew changes."
