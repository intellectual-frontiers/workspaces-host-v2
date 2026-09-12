# Implementation Plan: Hidden Default Clone Directory

**Branch**: `017-hidden-clone-directory` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Change `WORKSPACES_HOST_REPO`'s default from `~/workspaces-host-v2` to
`~/.workspaces-host-v2` in `home/shell.nix` and
`pkgs/workspaces-host-update`, and update every README reference and the
now-stale parts of feature 014's specs to match.

## Technical Context

**Language/Version**: Nix (`home/shell.nix`'s `home.sessionVariables`)
and POSIX shell (`pkgs/workspaces-host-update`'s fallback default) -
both already existing, just a literal string change.

**Primary Dependencies**: None new.

**Testing**: `nix build .#homeConfigurations.default.activationPackage`;
real activation, checked in an actual fish shell (not a bare
non-interactive one, per the lesson from feature 015's Java verification)
to confirm `$WORKSPACES_HOST_REPO` resolves to the dotted path;
`workspaces-host-update`'s no-repo-found error message printed against
the new default to confirm it's coherent.

**Constraints**: No behavior change beyond the literal default path - an
engineer with `$WORKSPACES_HOST_REPO` already set (in a fork, or their
own shell config) is unaffected either way.

## Constitution Check

- **Principle I**: No new flake inputs.
- **Principle V**: Single, small, self-contained change.

No violations.

## Project Structure

```text
home/shell.nix                                        # updated default
pkgs/workspaces-host-update/workspaces-host-update    # updated fallback default
README.md                                              # updated path references + a one-line "why dotted" note
specs/014-sandbox-sync-and-secrets-hygiene/spec.md    # updated to reflect new default (drift fix)
specs/014-sandbox-sync-and-secrets-hygiene/tasks.md   # updated to reflect new default (drift fix)
```
