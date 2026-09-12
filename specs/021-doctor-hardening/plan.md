# Implementation Plan: Doctor Hardening for Credentials & Beginner Pitfalls

**Branch**: `021-doctor-hardening` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add `gh`/`glab`/`openssh` to `home/tools.nix`. Extend `pkgs/doctor/doctor`
with two new sections: GitHub/GitLab authentication status, and a
"common pitfalls" set (SSH key permissions, WSL `/mnt` filesystem,
disk space, locale, `.netrc`, `umask`, Docker group membership).

## Technical Context

**Language/Version**: POSIX `/bin/sh` (`pkgs/doctor/doctor`, unwrapped -
it deliberately reports on the caller's live ambient environment, so
every new check is guarded with `command -v` rather than assuming a
fixed PATH).

**Primary Dependencies**: `gh`, `glab`, `openssh` (all confirmed present
in this flake's pinned nixpkgs before adding).

**Testing**: Built and activated in this project's own dev sandbox;
every new check exercised in both states for real - generated a real
wrong-permission SSH key and confirmed the warning, then `chmod`ed it and
confirmed it flips to pass; set `umask 000` and confirmed the warning; created
a `.netrc` with wrong permissions and confirmed the stronger warning.
`gh`/`glab` auth-status checks confirmed against this sandbox's actual
(unauthenticated) state.

**Constraints**: No check may crash or false-positive when its
underlying tool is absent.

## Constitution Check

- **Principle I**: No new flake inputs - `gh`/`glab`/`openssh` come from
  the already-pinned `nixpkgs`.
- **Principle V**: Single feature, single PR.

No violations.

## Project Structure

```text
home/tools.nix        # updated: gh, glab, openssh
pkgs/doctor/doctor    # updated: GitHub/GitLab auth section, common-pitfalls section
README.md             # updated: Health check section names the new coverage
```
