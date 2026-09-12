# Implementation Plan: Bulk Multi-Repo Git Tooling

**Branch**: `012-bulk-git-tooling` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add `git-extras` (a plain, unrestricted nixpkgs package) directly to
`home/tools.nix`'s `home.packages` list, and a new `pkgs/git-xargs`
prebuilt-binary port (not in nixpkgs) registered in `pkgs/default.nix`'s
aggregate, following the exact per-system asset-map pattern
`pkgs/backlog-md` already established. Both are unconditional across
this flake's four supported systems - unlike `surveilr` (a different,
separately-shipped feature), `git-xargs` publishes a release binary for
all four. Extend `pkgs/doctor/doctor`'s existing ported-tools check loop
and document both tools in README.md, next to the existing `mgit`
documentation they complement.

## Technical Context

**Language/Version**: Nix (package wiring), POSIX `/bin/sh` (one-line
doctor check-loop addition) - no new languages or runtimes.

**Primary Dependencies**: nixpkgs `git-extras` (pinned `nixos-24.11`);
`pkgs.fetchurl` + `pkgs.stdenvNoCC.mkDerivation` for the new
`pkgs/git-xargs` port (same category as `pkgs/backlog-md`'s
prebuilt-binary, per-system asset-map pattern).

**Testing**: `nix build .#homeConfigurations.default.activationPackage`;
real activation to confirm both tools land on `PATH` and
`git extras --version` / `git-xargs --help` each exit 0; `nix flake check
--all-systems` to confirm nothing regresses.

**Constraints**: No new flake inputs - `git-extras` comes from the
already-pinned `nixpkgs` input; `git-xargs`'s `fetchurl` hashes are
pinned explicitly per system (obtained via `nix store prefetch-file`
against the real release assets, not guessed).

## Constitution Check

- **Principle I**: No new flake inputs; `git-xargs`'s four per-system
  hashes are pinned exactly like `pkgs/backlog-md`'s own per-system
  `fetchurl` map.
- **Principle IV**: N/A - host-profile CLI tools, not a container/OCI-
  specific concern; they flow into the OCI image the same way every
  other `home.packages` entry already does.
- **Principle V**: Single feature, single PR - both tools are covered
  together since the original README treated them as one "bulk changes
  across many repos" capability, and both are pure package-wiring with
  no interacting logic to split apart.

No violations.

## Project Structure

```text
pkgs/git-xargs/default.nix   # new: prebuilt-binary port (fetchurl, per-system asset map)
pkgs/default.nix             # updated: register git-xargs
home/tools.nix               # updated: add git-extras
pkgs/doctor/doctor            # updated: check-loop entries for git-extras, git-xargs
README.md                    # new "Bulk changes across many repos" subsection (under mgit) + roadmap row
```
