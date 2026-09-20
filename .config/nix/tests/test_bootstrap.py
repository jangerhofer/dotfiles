"""Exercise bootstrap and README setup without installing or activating anything."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[3]
BOOTSTRAP = (ROOT / ".bootstrap.sh").read_text()
SETUP = (ROOT / "README.md").read_text().split("```bash\n", 1)[1].split("```", 1)[0]


def function(source, name):
    """Extract a current shell function, including its original body/interpreter calls."""
    body = source[source.index(name + "() "):]
    end = "\n)" if body.splitlines()[0].endswith("(") else "\n}"
    return body.split(end, 1)[0] + end + "\n"


class Sandbox(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="dotfiles-bootstrap-test-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.home = self.root / "home"
        self.bin = self.root / "bin"
        self.tmp = self.root / "tmp"
        self.outside = self.root / "outside-home"
        for directory in (self.home, self.bin, self.tmp, self.outside):
            directory.mkdir()
        # env resolves this alias even when the Python installation path has spaces.
        (self.bin / "fixture-python").symlink_to(sys.executable)
        # Build a child environment; never change the user's process environment.
        self.env = {
            "HOME": str(self.home),
            "PATH": str(self.bin) + ":/usr/bin:/bin",
            "TMPDIR": str(self.tmp),
            "TEST_ROOT": str(self.root),
            "TEST_MKTEMP": shutil.which("mktemp", path="/usr/bin:/bin"),
            "PYTHONIOENCODING": "utf-8",
        }
        # macOS can choose its per-user temp directory for bare `mktemp -d`
        # despite TMPDIR. An explicit template keeps every fixture under our root.
        self.shell_command("mktemp", """
            if [ "$#" -eq 1 ] && [ "$1" = -d ]; then
                exec "$TEST_MKTEMP" -d "$TMPDIR/activation.XXXXXX"
            fi
            exec "$TEST_MKTEMP" "$@"
        """)
        # Unexpected broadening of the extracted code must fail, not install anything.
        for command in ("nix", "sudo", "git", "curl", "brew"):
            self.executable(self.bin / command, "#!/bin/bash\nexit 99\n")

    def executable(self, path, contents):
        path.write_text(contents)
        path.chmod(0o755)

    def python_command(self, path, body):
        common = """\
import json, os, sys
from pathlib import Path
root = Path(os.environ['TEST_ROOT'])
args = sys.argv[1:]
with (root / 'events.bin').open('ab') as log:
    log.write(b'\\0'.join(value.encode() for value in [Path(sys.argv[0]).name, *args]) + b'\\0\\0')
"""
        # A Bash interpreter mistakenly forced onto this fixture fails at def main().
        self.executable(
            path,
            "#!/usr/bin/env fixture-python\ndef main():\n"
            + textwrap.indent(common + textwrap.dedent(body), "    ") + "\nmain()\n",
        )

    def shell_command(self, name, body):
        self.executable(self.bin / name, """#!/bin/bash
set -euo pipefail
{ printf '%s\\0' "${0##*/}" "$@"; printf '\\0'; } >> "$TEST_ROOT/events.bin"
""" + textwrap.dedent(body))

    def run_shell(self, source, extra=None):
        return subprocess.run(
            ["/bin/bash", "-c", "set -euo pipefail\n" + source],
            cwd=self.outside, env={**self.env, **(extra or {})},
            text=True, capture_output=True, timeout=30,
        )

    def events(self):
        path = self.root / "events.bin"
        if not path.exists():
            return []
        records = [record.decode().split("\0") for record in path.read_bytes().split(b"\0\0") if record]
        return [{"command": record[0], "args": record[1:]} for record in records]

    def reset_records(self):
        for name in ("events.bin", "activated.json", "output-link"):
            path = self.root / name
            if path.exists():
                path.unlink()


class BootstrapTests(Sandbox):
    def setUp(self):
        super().setUp()
        activation = self.root / "activation"
        activation.mkdir()
        self.python_command(activation / "activate", """
            (root / 'activated.json').write_text(json.dumps({
                'backup': os.environ['HOME_MANAGER_BACKUP_EXT'],
                'interpreter': sys.executable,
            }))
            sys.exit(int(os.environ.get('ACTIVATION_EXIT', '0')))
        """)
        self.shell_command("nix", """
            case "$1" in
                build)
                    [ "$#" -eq 4 ] && [ "$3" = --out-link ]
                    case "$4" in
                        "$TMPDIR"/*/home-manager) ;;
                        *) printf 'Unexpected fixture output: %s (TMPDIR=%s)\\n' "$4" "$TMPDIR" >&2; exit 98 ;;
                    esac
                    printf '%s' "$4" > "$TEST_ROOT/output-link"
                    [ "${BUILD_FAIL:-0}" = 0 ] || exit 73
                    ln -s "$TEST_ROOT/activation" "$4"
                    ;;
                eval)
                    [ "$#" -eq 3 ] && [ "$2" = --raw ]
                    [ "${EVAL_FAIL:-0}" = 0 ] || exit 72
                    case "$3" in
                        *.config.home.username) printf '%s' "${PROFILE_USER:-fixture-user}" ;;
                        *.config.home.homeDirectory) printf '%s' "${PROFILE_HOME:-$HOME}" ;;
                        *.pkgs.stdenv.hostPlatform.system) printf '%s' "${PROFILE_SYSTEM:-x86_64-linux}" ;;
                        *) exit 98 ;;
                    esac
                    ;;
                *) exit 98 ;;
            esac
        """)
        self.shell_command("uname", """
            [ "$*" = -m ]
            printf '%s\\n' "${MACHINE_ARCH:-x86_64}"
        """)
        self.shell_command("id", """
            [ "$*" = -un ]
            printf '%s\\n' fixture-user
        """)

    def test_shell_syntax(self):
        for source in (BOOTSTRAP, SETUP):
            with self.subTest(source="bootstrap" if source == BOOTSTRAP else "README"):
                result = subprocess.run(
                    ["/bin/bash", "-n"], input=source, env=self.env,
                    text=True, capture_output=True, timeout=30,
                )
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_activation_honors_shebang_and_backup_environment(self):
        runner = function(BOOTSTRAP, "activate_home_manager_flake") + (
            "activate_home_manager_flake 'fixture#homeConfigurations.test'\n"
            "later_step() { :; }; later_step\n"
        )
        for extra, backup in (({}, "before-home-manager"), ({"HOME_MANAGER_BACKUP_EXT": "saved"}, "saved")):
            with self.subTest(backup=backup):
                self.reset_records()
                result = self.run_shell(runner, extra)
                self.assertEqual(result.returncode, 0, result.stderr)
                record = json.loads((self.root / "activated.json").read_text())
                self.assertEqual(record["backup"], backup)
                self.assertEqual(Path(record["interpreter"]).resolve(), Path(sys.executable).resolve())
                self.assertFalse(Path((self.root / "output-link").read_text()).parent.exists())

    def test_activation_failure_and_build_failure_clean_temporary_directory(self):
        runner = function(BOOTSTRAP, "activate_home_manager_flake") + (
            "activate_home_manager_flake 'fixture#homeConfigurations.test'\n"
            "touch \"$TEST_ROOT/continued\"\n"
        )
        for extra, status, activated in (({"ACTIVATION_EXIT": "42"}, 42, True), ({"BUILD_FAIL": "1"}, 73, False)):
            with self.subTest(extra=extra):
                self.reset_records()
                result = self.run_shell(runner, extra)
                self.assertEqual(result.returncode, status, result.stderr)
                self.assertEqual((self.root / "activated.json").exists(), activated)
                self.assertFalse(Path((self.root / "output-link").read_text()).parent.exists())
                self.assertFalse((self.root / "continued").exists())

    def test_darwin_rebuild_honors_shebang_and_arguments(self):
        self.shell_command("sudo", """
            [ "$1" = env ] && [ "$2" = HOME=/var/root ]
            [ "$3" = 'NIX_CONFIG=experimental-features = nix-command flakes' ]
            case "$4" in "$TEST_ROOT/bin/darwin-rebuild"|bash) ;; *) exit 98 ;; esac
            exec "$@"
        """)
        self.python_command(self.bin / "darwin-rebuild", """
            (root / 'darwin.json').write_text(json.dumps({
                'home': os.environ['HOME'], 'nix_config': os.environ['NIX_CONFIG'],
                'interpreter': sys.executable, 'args': args,
            }))
        """)
        branch = BOOTSTRAP.split("# Use direct flake configuration\n", 1)[1].split('    echo "🏠', 1)[0]
        result = self.run_shell(function(BOOTSTRAP, "run_as_root") + "DARWIN_FLAKE='fixture path#default'\n" + branch)
        self.assertEqual(result.returncode, 0, result.stderr)
        record = json.loads((self.root / "darwin.json").read_text())
        self.assertEqual(record["home"], "/var/root")
        self.assertEqual(record["nix_config"], "experimental-features = nix-command flakes")
        self.assertEqual(record["args"], ["switch", "--flake", "fixture path#default"])
        self.assertEqual(Path(record["interpreter"]).resolve(), Path(sys.executable).resolve())

    def linux_runner(self):
        helpers = "".join(function(BOOTSTRAP, name) for name in (
            "current_user", "check_home_manager_user", "activate_home_manager_flake",
        ))
        deploy = BOOTSTRAP.split("# Deploy environment\n", 1)[1].split("# Set Nushell as default shell\n", 1)[0]
        return helpers + "OSTYPE=linux-gnu\n" + deploy

    def test_linux_selects_persistent_default_and_custom_profiles(self):
        cases = (
            ("x86_64", "x86_64-linux", None, "linux-x86_64"),
            ("aarch64", "aarch64-linux", None, "linux-aarch64"),
            ("arm64", "aarch64-linux", None, "linux-aarch64"),
            ("aarch64", "aarch64-linux", "vps-aarch64", "vps-aarch64"),
        )
        for arch, system, selected, expected in cases:
            with self.subTest(arch=arch, selected=selected):
                self.reset_records()
                extra = {"MACHINE_ARCH": arch, "PROFILE_SYSTEM": system}
                if selected:
                    extra["HOME_MANAGER_PROFILE_NAME"] = selected
                result = self.run_shell(self.linux_runner(), extra)
                self.assertEqual(result.returncode, 0, result.stderr)
                builds = [event for event in self.events() if event["command"] == "nix" and event["args"][0] == "build"]
                self.assertEqual(len(builds), 1)
                self.assertEqual(builds[0]["args"][1], str(self.home / ".config/nix") + "#homeConfigurations." + expected + ".activationPackage")
                self.assertTrue((self.root / "activated.json").exists())

    def test_linux_rejects_mismatched_user_home_architecture_and_failed_eval(self):
        cases = (
            ({"PROFILE_USER": "someone-else"}, "configured for"),
            ({"PROFILE_HOME": str(self.root / "other-home")}, "configured for"),
            ({"MACHINE_ARCH": "riscv64"}, "Unsupported Linux architecture"),
            ({"HOME_MANAGER_PROFILE_NAME": "linux-aarch64", "PROFILE_SYSTEM": "aarch64-linux"}, "targets 'aarch64-linux'"),
            ({"EVAL_FAIL": "1"}, None),
        )
        for extra, message in cases:
            with self.subTest(extra=extra):
                self.reset_records()
                result = self.run_shell(self.linux_runner(), extra)
                self.assertNotEqual(result.returncode, 0)
                if message:
                    self.assertIn(message, result.stdout)
                self.assertFalse((self.root / "activated.json").exists())
                self.assertFalse(any(event["command"] == "nix" and event["args"][0] == "build" for event in self.events()))


class ReadmeSetupTests(Sandbox):
    PATHS = (".config/nix/nix.conf", "README.md", "notes with spaces.txt", ".broken-link", ".bootstrap.sh")

    def setUp(self):
        super().setUp()
        self.env["TEST_PATHS"] = "\n".join(self.PATHS)
        for relative in self.PATHS:
            path = self.home / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            if relative == ".broken-link":
                path.symlink_to("missing-target")
            else:
                path.write_text("original: " + relative + "\n")
        self.shell_command("git", """
            if [ "$1" = clone ]; then
                [ "$2" = --bare ]
                [ "$3" = https://github.com/jangerhofer/dotfiles.git ]
                [ "$4" = "$HOME/.dotfiles" ]
                mkdir "$HOME/.dotfiles"
                exit 0
            fi
            [ "$1" = -C ] && [ "$2" = "$HOME" ]
            [ "$3" = "--git-dir=$HOME/.dotfiles" ] && [ "$4" = "--work-tree=$HOME" ]
            shift 4
            case "$1" in
                ls-tree)
                    [ "$*" = 'ls-tree -r -z --name-only HEAD' ]
                    while IFS= read -r path; do printf '%s\\0' "$path"; done <<< "$TEST_PATHS"
                    ;;
                checkout)
                    while IFS= read -r path; do
                        target="$HOME/$path"
                        [ ! -e "$target" ] && [ ! -L "$target" ]
                        mkdir -p "${target%/*}"
                        if [ "$path" = .bootstrap.sh ]; then
                            printf '#!/bin/bash\\nprintf done > "$TEST_ROOT/bootstrap-ran"\\n' > "$target"
                            chmod +x "$target"
                        else
                            printf 'checkout: %s\\n' "$path" > "$target"
                        fi
                    done <<< "$TEST_PATHS"
                    ;;
                *) [ "$*" = 'config --local status.showUntrackedFiles no' ] ;;
            esac
        """)
        self.executable(self.bin / "mv", """#!/bin/bash
if [ "${FAIL_MV:-0}" = 1 ]; then
    exit 37
fi
exec /bin/mv "$@"
""")

    def test_setup_backs_up_all_paths_from_outside_home_and_keeps_unique_backups(self):
        result = self.run_shell(SETUP)
        self.assertEqual(result.returncode, 0, result.stderr)
        backups = list(self.home.glob(".config-backup.*"))
        self.assertEqual(len(backups), 1)
        first = backups[0]
        for relative in self.PATHS:
            with self.subTest(path=relative):
                path = first / relative
                if relative == ".broken-link":
                    self.assertTrue(path.is_symlink())
                    self.assertEqual(os.readlink(path), "missing-target")
                else:
                    self.assertEqual(path.read_text(), "original: " + relative + "\n")
        self.assertEqual((self.root / "bootstrap-ran").read_text(), "done")

        # Repeat only the backup portion; cloning again requires a fresh destination.
        backup = "# Back up existing files" + SETUP.split("# Back up existing files", 1)[1].split("# Checkout dotfiles", 1)[0]
        result = self.run_shell(function(SETUP, "dotfiles") + backup)
        self.assertEqual(result.returncode, 0, result.stderr)
        backups = list(self.home.glob(".config-backup.*"))
        self.assertEqual(len(backups), 2)
        second = next(path for path in backups if path != first)
        self.assertEqual((first / "README.md").read_text(), "original: README.md\n")
        self.assertEqual((second / "README.md").read_text(), "checkout: README.md\n")

    def test_failed_backup_stops_before_checkout_and_bootstrap(self):
        result = self.run_shell(SETUP, {"FAIL_MV": "1"})
        self.assertEqual(result.returncode, 37, result.stderr)
        self.assertFalse(any("checkout" in event["args"] for event in self.events()))
        self.assertFalse((self.root / "bootstrap-ran").exists())
        self.assertEqual((self.home / self.PATHS[0]).read_text(), "original: " + self.PATHS[0] + "\n")


if __name__ == "__main__":
    unittest.main()
