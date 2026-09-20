"""Regression checks for Nushell helpers, without activating any configuration.

Only temporary Git repositories receive fixture commits. Nushell does not load
user config/history, and nix, nm, and brew are mocked. Extracted HOME references
use a test variable rather than changing the real HOME environment variable.
"""

import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


NIX_ROOT = Path(__file__).resolve().parents[1]
SOURCE = (NIX_ROOT / "modules/nushell.nix").read_text()
NU = shutil.which("nu")
GIT = shutil.which("git")


def extract(start, end):
    return SOURCE[SOURCE.index(start):SOURCE.index(end)]


def run(args, *, cwd, env):
    result = subprocess.run(
        args, cwd=cwd, env=env, text=True, capture_output=True, timeout=60,
    )
    if result.returncode:
        raise AssertionError(
            f"Command {args[0]!r} exited {result.returncode}:\n{result.stderr}\n{result.stdout}"
        )
    return result.stdout


@unittest.skipUnless(NU and GIT, "nu and git are required")
class ShellWorkflows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="dotfiles shell tests ")
        cls.addClassCleanup(cls.temp.cleanup)
        cls.root = Path(cls.temp.name)
        cls.fixture_home = cls.root / "home"
        cls.project = cls.root / "separate project"
        cls.outside = cls.root / "outside"
        cls.mock_bin = cls.root / "mock bin"
        cls.empty_bin = cls.root / "empty bin"
        for path in [cls.fixture_home, cls.project, cls.outside, cls.mock_bin, cls.empty_bin]:
            path.mkdir()
        cls.env = {
            key: value for key, value in os.environ.items()
            if not key.startswith(("GIT_", "HOMEBREW_"))
            and key not in {"INFOPATH", "MANPATH", "BASH_ENV", "ENV"}
        }
        cls.env.update(
            GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull,
            DOTFILES_TEST_HOME=str(cls.fixture_home),
        )
        cls.dot_git = [GIT, f"--git-dir={cls.fixture_home / '.dotfiles'}", f"--work-tree={cls.fixture_home}"]
        cls.project_git = [GIT, "-C", str(cls.project)]
        run([GIT, "init", "-q", "--bare", "-b", "dot-branch", str(cls.fixture_home / ".dotfiles")], cwd=cls.root, env=cls.env)
        run([GIT, "init", "-q", "-b", "project-branch", str(cls.project)], cwd=cls.root, env=cls.env)
        (cls.fixture_home / ".dotfiles/info/exclude").write_text(".dotfiles/\n")
        cls.config_dir = cls.fixture_home / ".config/nix"
        cls.config_dir.mkdir(parents=True)
        cls.lock = cls.config_dir / "flake.lock"
        cls.lock.write_text('{"fixture": "before"}\n')
        for directory, git, prefix in [
            (cls.fixture_home, cls.dot_git, "dot"),
            (cls.project, cls.project_git, "project"),
        ]:
            (directory / f"{prefix}-file").write_text("fixture\n")
            run(git + ["add", "."], cwd=directory, env=cls.env)
            # No user signing agent, hook, or global Git configuration is used.
            run(git + ["-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
                       "-c", "commit.gpgSign=false", "-c", f"core.hooksPath={cls.empty_bin}",
                       "commit", "-q", "-m", "test: seed temporary shell fixture"], cwd=directory, env=cls.env)
            run(git + ["tag", f"{prefix}-tag"], cwd=directory, env=cls.env)
            run(git + ["remote", "add", f"{prefix}-remote", str(cls.root / f"{prefix}-upstream")], cwd=directory, env=cls.env)
            run(git + ["config", f"alias.{prefix}-switch", "switch"], cwd=directory, env=cls.env)
            run(git + ["config", "alias.jump", "switch" if prefix == "dot" else "push"], cwd=directory, env=cls.env)
        cls.lock.write_text('{"fixture": "after"}\n')
        brew = cls.mock_bin / "brew"
        brew.write_text('''#!/bin/sh
case "$1" in
  --prefix) printf '%s\\n' "$DOTFILES_TEST_BREW_PREFIX" ;;
  --cellar) printf '%s/Cellar\\n' "$DOTFILES_TEST_BREW_PREFIX" ;;
  --repository) printf '%s/Repository\\n' "$DOTFILES_TEST_BREW_PREFIX" ;;
  *) exit 99 ;;
esac
''')
        brew.chmod(0o755)

    def nu(self, code, *, cwd=None, env=None):
        return run(
            [NU, "--no-config-file", "--no-history", "-c", re.sub(r"\$env\.HOME\b", "$env.DOTFILES_TEST_HOME", code)],
            cwd=cwd or self.project, env=env or self.env,
        )

    def test_git_completions_follow_the_selected_repository(self):
        helpers = extract("      def complete-git-subcommands-and-aliases", "      # Disable nushell prompt indicators")
        wrappers = extract("      def --wrapped g [", "      def dtlg []")
        self.assertIn('command?: string@"complete-dt-subcommands-and-aliases"', wrappers)
        self.assertIn('...args: string@"complete-dt-args"', wrappers)
        result = json.loads(self.nu(helpers + wrappers + '''
            print ({
              ordinary: (complete-git-args "g switch ")
              ordinary_alias: (complete-git-args "g project-switch ")
              project_remote: (complete-git-args "g push ")
              project_jump: (complete-git-args "g jump ")
              project_commands: (complete-git-subcommands-and-aliases)
              dot_commands: (complete-dt-subcommands-and-aliases)
              dot_command_context: (complete-dt-args "dt ")
              dot_branch: (complete-dt-args "dt switch ")
              dot_alias: (complete-dt-args "dt dot-switch ")
              dot_jump: (complete-dt-args "dt jump ")
              dot_remote: (complete-dt-args "dt push ")
              dot_tag: (complete-dt-args "dt tag ")
              dot_file: (complete-dt-args "dt add ")
              dot_cursor: (complete-dt-args "dt switch " 10)
              git_dir_leaked: ($env.GIT_DIR? != null)
              project_after_dt: (complete-git-args "g switch ")
            } | to json)
        '''))
        expected = {
            "ordinary": ["project-branch"], "ordinary_alias": ["project-branch"],
            "project_remote": ["project-remote"], "project_jump": ["project-remote"],
            "dot_branch": ["dot-branch"], "dot_alias": ["dot-branch"],
            "dot_jump": ["dot-branch"], "dot_remote": ["dot-remote"],
            "dot_tag": ["dot-tag"], "dot_file": [".config/nix/flake.lock", "dot-file"],
            "dot_cursor": ["dot-branch"], "git_dir_leaked": False,
            "project_after_dt": ["project-branch"],
        }
        for key, value in expected.items():
            with self.subTest(completion=key):
                self.assertEqual(result[key], value)
        for key in ["dot_commands", "dot_command_context"]:
            self.assertIn("dot-switch", result[key])
            self.assertNotIn("project-switch", result[key])
        self.assertIn("project-switch", result["project_commands"])
        self.assertNotIn("dot-switch", result["project_commands"])
        outside = json.loads(self.nu(helpers + '''
            print ({aliases: (complete-git-aliases), resolved: (resolve-git-command "switch"), branches: (complete-git-args "g switch "), commands: (complete-git-subcommands-and-aliases)} | to json)
        ''', cwd=self.outside))
        self.assertEqual(outside["aliases"], [])
        self.assertEqual(outside["resolved"], "switch")
        self.assertEqual(outside["branches"], [])
        self.assertIn("switch", outside["commands"])

    def test_lockfile_preview_and_update_order_from_any_directory(self):
        workflows = extract("      def ncheck []", "      def nclean [")
        mocks = '''
            def --wrapped nix [...args: string] {
              if $args != [flake update --flake ($env.DOTFILES_TEST_HOME | path join .config nix)] {
                error make {msg: "Unexpected nix arguments"}
              }
              print "fixture:update"
            }
            def nm [] { print "fixture:activate" }
        '''
        for cwd in [self.fixture_home, self.config_dir, self.outside]:
            for command in ["ncheck", "nfull"]:
                with self.subTest(cwd=cwd.name, command=command):
                    output = self.nu(mocks + workflows + "\n" + command, cwd=cwd)
                    self.assertIn("diff --git a/.config/nix/flake.lock", output)
                    self.assertIn('-{"fixture": "before"}', output)
                    self.assertIn('+{"fixture": "after"}', output)
                    if command == "nfull":
                        self.assertLess(output.index("fixture:update"), output.index("diff --git"))
                        self.assertLess(output.index("diff --git"), output.index("fixture:activate"))
                    else:
                        self.assertNotIn("fixture:update", output)
                        self.assertNotIn("fixture:activate", output)

    def brew_state(self, *, present=True, initial=None):
        block = extract("            let brew_bin =", "            # Initialize pay-respects")
        env = dict(self.env, PATH=str(self.mock_bin if present else self.empty_bin),
                   DOTFILES_TEST_BREW_PREFIX=str(self.root / "Homebrew with spaces"))
        env.update(initial or {})
        return json.loads(self.nu('''
            def snapshot [] {
              {path: $env.PATH, prefix: $env.HOMEBREW_PREFIX?, cellar: $env.HOMEBREW_CELLAR?,
               repository: $env.HOMEBREW_REPOSITORY?, info: $env.INFOPATH?, man: $env.MANPATH?}
            }
            def --env setup-brew [] {
        ''' + block + '''
            }
            let before = (snapshot)
            setup-brew
            let first = (snapshot)
            setup-brew
            print ({before: $before, first: $first, second: (snapshot)} | to json)
        ''', env=env))

    def test_homebrew_values_paths_and_repeated_initialization(self):
        prefix = str(self.root / "Homebrew with spaces")
        for initial, info, man in [
            ({}, prefix + "/share/info:", None),
            ({"INFOPATH": "/custom/info:", "MANPATH": ":/custom/man:"}, prefix + "/share/info:/custom/info:", ":/custom/man"),
            ({"INFOPATH": "", "MANPATH": ""}, prefix + "/share/info:", ""),
        ]:
            with self.subTest(initial=initial):
                state = self.brew_state(initial=initial)
                self.assertEqual(state["first"], state["second"])
                self.assertEqual(state["first"]["path"], state["before"]["path"])
                self.assertEqual(state["first"]["prefix"], prefix)
                self.assertEqual(state["first"]["cellar"], prefix + "/Cellar")
                self.assertEqual(state["first"]["repository"], prefix + "/Repository")
                self.assertEqual(state["first"]["info"], info)
                self.assertEqual(state["first"]["man"], man)

    def test_homebrew_absent_preserves_environment(self):
        state = self.brew_state(present=False, initial={
            "HOMEBREW_PREFIX": "untouched", "INFOPATH": "/custom/info", "MANPATH": "/custom/man",
        })
        self.assertEqual(state["before"], state["first"])
        self.assertEqual(state["first"], state["second"])

    def test_nom_uses_the_packaged_executable(self):
        aliases = extract("    shellAliases = {", "    # Nushell configuration")
        self.assertNotRegex(aliases, r"(?m)^\s*nom\s*=")
        home_module = (NIX_ROOT / "modules/home.nix").read_text()
        self.assertIn("    nix-output-monitor\n", home_module)


if __name__ == "__main__":
    unittest.main()
