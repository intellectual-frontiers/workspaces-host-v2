# Implementation Plan: Compliance & Observability Tooling

**Branch**: `011-compliance-observability-tooling` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add `osquery`, `cnquery`, `steampipe`, and `openobserve` (all plain,
unconditionally-available-except-`osquery` nixpkgs packages) directly to
`home/tools.nix`'s `home.packages` list, and a new `pkgs/surveilr`
prebuilt-binary port (this flake's nixpkgs doesn't carry it) registered
in `pkgs/default.nix`'s aggregate. Both `osquery` (Linux-only in
nixpkgs) and `surveilr` (release binaries only for
`x86_64-linux`/`x86_64-darwin`) are wired in conditionally so `nix flake
check --all-systems` keeps evaluating cleanly on every system. Extend
`pkgs/doctor/doctor` with checks for all five, and document them in
README.md.

## Technical Context

**Language/Version**: Nix (package wiring), POSIX `/bin/sh` (doctor
check additions) - no new languages or runtimes.

**Primary Dependencies**: nixpkgs `osquery`/`cnquery`/`steampipe`/
`openobserve` (pinned `nixos-24.11`); `pkgs.fetchurl` +
`pkgs.stdenvNoCC.mkDerivation` + `pkgs.unzip` for the new `pkgs/surveilr`
port (same category as `pkgs/backlog-md`'s prebuilt-binary pattern).

**Testing**: `nix build .#homeConfigurations.default.activationPackage`;
real activation to confirm all five tools land on `PATH` and their
version/help invocations exit 0; `nix flake check --all-systems` to
confirm the two conditional packages (`osquery`, `surveilr`) don't break
evaluation on the systems where they're absent.

**Constraints**: No new flake inputs - everything comes from the
already-pinned `nixpkgs` input plus a direct GitHub-releases `fetchurl`
for `surveilr`, exactly like `pkgs/backlog-md` already does for its own
third-party binary.

## Constitution Check

- **Principle I**: No new flake inputs; `surveilr`'s `fetchurl` hash is
  pinned explicitly (obtained via `nix store prefetch-file` against the
  real release asset, not guessed), so the derivation is exactly as
  reproducible as any other fixed-output fetch already in this repo
  (`pkgs/backlog-md`, `pkgs/specify-cli`).
- **Principle IV**: N/A - these are host-profile CLI tools, not a
  container/OCI-specific concern; they flow into the OCI image the same
  way every other `home.packages` entry already does.
- **Principle V**: Single feature, single PR - the two dropped
  capabilities from the gap analysis (SOC2 tooling + `OpenObserve`, and
  `surveilr`) are covered together here since the original README treated
  them as one paragraph/one health-check block, and both are pure
  package-wiring with no interacting logic to split apart.

No violations.

## Project Structure

```text
pkgs/surveilr/default.nix   # new: prebuilt-binary port (fetchurl from GitHub releases)
pkgs/default.nix            # updated: register surveilr, conditionally (x86_64-linux/x86_64-darwin only)
home/tools.nix              # updated: add cnquery/steampipe/openobserve unconditionally, osquery on Linux only
pkgs/doctor/doctor          # updated: checks for osqueryi/cnquery/steampipe/openobserve/surveilr
README.md                   # new "Compliance & observability tooling" section + roadmap row
```
