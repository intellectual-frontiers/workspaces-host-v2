# Implementation Plan: Local Configuration Isolation & Real-Identity Profiles

**Branch**: `019-local-config-isolation` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add impure, real-identity flake outputs (`current`, `current-<persona>`)
alongside the existing fixed-identity ones (unchanged, still what CI
uses). Add a local, outside-the-repo override mechanism
(`~/.config/workspaces-host/local.nix`, auto-imported if present) so
personal config (git identity, real secrets) never touches a tracked
file. Update `home/git.nix` (`lib.mkDefault`), `pkgs/workspaces-host-update`
(new default profile + `--impure` + `whoami` fallback), `pkgs/doctor/doctor`
(local.nix + placeholder-email checks), and README throughout.

## Technical Context

**Language/Version**: Nix (`flake.nix`, `home/default.nix`,
`home/git.nix`), POSIX shell (`pkgs/workspaces-host-update`,
`pkgs/doctor/doctor`).

**Primary Dependencies**: None new - `builtins.getEnv`/
`builtins.currentSystem` are core Nix builtins; `--impure` is already
supported by both `nix build` and `home-manager switch` (confirmed via
`home-manager --help` before implementing).

**Testing**: Built and activated `homeConfigurations.current` for real in
this project's own dev sandbox as its actual user (not "workspace") -
this is what caught two real bugs during implementation: `$USER` being
unset even though `whoami` works, and an infinite-recursion module-system
bug from referencing `pkgs` while computing the same module's own
`imports` list. Verified `local.nix`'s override actually reaches the
generated `~/.config/git/config` by inspecting that file directly (not
just `git config --get`, which in this particular sandbox is masked by a
pre-existing, harness-managed `~/.gitconfig` and repo-local `.git/config`
unrelated to this feature). Confirmed `nix flake check --all-systems`
(no `--impure`) still passes unchanged.

**Constraints**: Zero behavior change to any existing pure
`homeConfigurations.*` attribute or to `nix flake check`.

## Constitution Check

- **Principle I**: No new flake inputs.
- **Principle V**: One feature covering one theme (real identity +
  local-only overrides), even though it touches several files.

No violations.

## Project Structure

```text
flake.nix                                           # updated: current/current-<persona> outputs
home/default.nix                                    # updated: conditional local.nix import
home/git.nix                                        # updated: lib.mkDefault on userName/userEmail
local.nix.example                                    # new: tracked template
pkgs/workspaces-host-update/workspaces-host-update  # updated: default profile=current, --impure, whoami fallback
pkgs/doctor/doctor                                   # updated: local.nix check, placeholder-email distinction
README.md                                            # updated: current/--impure install path, local.nix docs, simplified macOS section
```
