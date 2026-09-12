# Implementation Plan: Sandbox Sync & Secrets Hygiene

**Branch**: `014-sandbox-sync-and-secrets-hygiene` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add `pkgs/workspaces-host-update` (git pull + `home-manager switch` in one
command), a `WORKSPACES_HOST_REPO` session variable, and a once-a-day
backgrounded fish nudge (`home/shell.nix`) so engineers notice when `main`
has moved. Add `gitleaks` to every profile. Document all of it plus the
existing (unchanged) `home/secrets.nix`/direnv mechanism's use for
short-lived GitHub/GitLab tokens in README.md.

## Technical Context

**Language/Version**: POSIX `/bin/sh` for the update script; fish for the
nudge (`home/shell.nix`'s `interactiveShellInit`, already fish-only).

**Primary Dependencies**: `git`, `home-manager` (both already present in
every profile).

**Testing**: `nix build .#homeConfigurations.default.activationPackage`;
`fish -n` against the generated `config.fish` (syntax only); a *real*
interactive fish shell exercised against a local bare-repo fixture (one
commit ahead of a clone) to confirm the nudge actually fires, is silent on
a same-day second run, and doesn't block shell startup - syntax-checking
alone previously missed a real bug in a sibling feature (pgpass's `env`
subcommand), so this feature's fish logic gets the same real-execution
bar, not just `fish -n`.

**Constraints**: The nudge must never fail a shell if there's no network,
no `$WORKSPACES_HOST_REPO`, or it isn't yet a git repo - all silently
skipped.

## Constitution Check

- **Principle I**: No new flake inputs.
- **Principle V**: Single feature, single PR (touches several small
  files but is one coherent capability: "notice and apply upstream
  updates" + "document existing secrets tooling for a concrete case").

No violations.

## Project Structure

```text
pkgs/workspaces-host-update/workspaces-host-update  # new: git pull + home-manager switch
pkgs/workspaces-host-update/default.nix             # new: package definition
pkgs/default.nix                                    # updated: register it
home/shell.nix                                      # updated: WORKSPACES_HOST_REPO session var + daily nudge
home/tools.nix                                      # updated: add gitleaks
pkgs/doctor/doctor                                   # updated: WORKSPACES_HOST_REPO check
README.md                                            # updated: clone step + two new sections
```
