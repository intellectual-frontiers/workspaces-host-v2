# Implementation Plan: One-Step Installer

**Branch**: `020-one-step-installer` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add `install.sh` at the repo root: a plain POSIX-shell bootstrap script
covering prerequisites (distro-sensed), Nix install, flakes enablement,
clone-or-update, and build+activate (`current`, `--impure`). Rewrite the
README's Windows/WSL walkthrough to lead with this one command, keeping
the manual equivalent as a clearly-labeled fallback section.

## Technical Context

**Language/Version**: POSIX `/bin/sh` (verified against both `sh -n` and
`dash -n`, not just bash - this script must run correctly under
`sh -c "$(curl ...)"` on any target shell).

**Primary Dependencies**: None new - only tools every target machine
already has or `install.sh` itself installs (`curl`, `git`, `apt`/`dnf`/
`pacman`, Nix).

**Testing**: Real execution in this project's own dev sandbox (Nix
already present, so the actual Nix-install branch is exercised as
"already installed" rather than run for real - `nixos.org` is blocked by
this sandbox's own network policy, confirmed via its proxy status
endpoint, not a real-world constraint): fresh clone + build + activate,
then a second run to confirm full idempotency (pull instead of clone, no
duplicate `nix.conf` line), then a run against a pre-existing non-git
directory to confirm the clear-error path. Caught and fixed a real
bug during this testing: the first draft used bash's `<(...)` process
substitution, which is invalid under strict POSIX `sh`/`dash`.

**Constraints**: Must not be a Nix package (it bootstraps Nix itself, so
it can't depend on anything this flake provides) - stays a plain
top-level shell script, invoked directly via `curl`.

## Constitution Check

- **Principle I**: N/A - `install.sh` is outside the flake entirely, not
  a pinned input or package.
- **Principle V**: Single feature, single PR.

No violations.

## Project Structure

```text
install.sh   # new: one-step bootstrap (prereqs, Nix, flakes, clone, build+activate)
README.md    # updated: Windows/WSL walkthrough leads with install.sh; manual steps kept as a fallback section; "Other platforms" simplified
```
