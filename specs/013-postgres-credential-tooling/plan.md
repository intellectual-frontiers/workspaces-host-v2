# Implementation Plan: PostgreSQL Credential Tooling

**Branch**: `013-postgres-credential-tooling` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add `home/postgres.nix` (declarative `~/.psqlrc`, non-clobbering
`~/.pgpass` bootstrap via `pkgs.writeText` + `install -m 600`) and a new
`pkgs/pgpass` POSIX-shell CLI porting a deliberate subset of
`netspective-labs/sql-aide`'s `pgpass.ts`. Extend `pkgs/doctor/doctor` and
README.md accordingly.

## Technical Context

**Language/Version**: POSIX `/bin/sh` + `jq` for the CLI (matches
`pkgs/mgit`/`pkgs/sensitivectl`); Nix `home.file`/`home.activation` for
the dotfiles, matching `home/workspaces.nix`'s non-clobbering-stub pattern.

**Primary Dependencies**: `jq`, `gnused`, `gawk`, `coreutils` (all already
used elsewhere in this repo).

**Testing**: `nix build .#homeConfigurations.default.activationPackage`;
real activation to confirm `~/.psqlrc` and a mode-600 `~/.pgpass` stub are
created, and that a second activation doesn't touch an edited `.pgpass`;
a real `~/.pgpass` entry exercised through every `pgpass` subcommand.

**Constraints**: No real credentials in any Nix-store-managed file (see
spec Assumptions / Constitution Principle III).

## Constitution Check

- **Principle I**: No new flake inputs.
- **Principle III**: `.pgpass` is user-provided secret state, never
  generated with real values by this module - same treatment as
  `sensitivectl`'s config and `mgit.json`.
- **Principle V**: Single feature, single PR.

No violations.

## Project Structure

```text
pkgs/pgpass/pgpass         # new: ls/test/env/url/psql POSIX shell tool
pkgs/pgpass/default.nix    # new: package definition
pkgs/default.nix           # updated: register pgpass
home/postgres.nix          # new: .psqlrc (declarative) + .pgpass (stub, non-clobbering)
home/default.nix           # updated: import ./postgres.nix
pkgs/doctor/doctor         # updated: pgpass + .pgpass/.psqlrc checks
README.md                  # new "PostgreSQL credentials" section
```
