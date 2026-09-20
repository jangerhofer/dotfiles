#!/bin/bash
set -euo pipefail

dotfiles_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
flake_dir="$dotfiles_root/.config/nix"
flake_ref="path:$flake_dir"

for required_command in git nix nu python3; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        echo "Missing required command: $required_command" >&2
        exit 1
    fi
done

echo "Checking bootstrap and validation-script syntax..."
for script in "$dotfiles_root/.bootstrap.sh" "$flake_dir/scripts/check-dotfiles.sh"; do
    /bin/bash -n "$script"
done

echo "Checking workflows in temporary fixtures..."
python3 -B -m unittest discover -s "$flake_dir/tests" -p 'test_*.py' -v

echo "Evaluating all Nix configurations..."
nix flake check --all-systems --no-build --no-write-lock-file "$flake_ref" "$@"

echo "Checking profile targets and Git signing..."
nix eval --json --no-write-lock-file "${flake_ref}#homeConfigurations" \
    --apply "$(cat "$flake_dir/tests/profile-checks.nix")" "$@"

echo "All dotfiles checks passed."
