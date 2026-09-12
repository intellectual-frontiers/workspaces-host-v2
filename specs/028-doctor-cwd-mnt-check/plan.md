# Implementation Plan: Detect the Current Directory Under /mnt, Not Just $HOME

**Branch**: `028-doctor-cwd-mnt-check` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add a second `case "$PWD" in /mnt/*)` check to `pkgs/doctor/doctor`,
alongside the existing `$HOME` check, inside the same WSL guard.
Explain the underlying WSL cross-filesystem performance issue and its
fix (`~/workspaces`/`mgit`) in the README's WSL walkthrough and `mgit`
section, and reference the new check from the Health check summary.

## Technical Context

**Language/Version**: POSIX `/bin/sh` (`pkgs/doctor/doctor`), Markdown
(README.md).

**Primary Dependencies**: None new.

**Testing**: The new check's logic verified directly (not just read):
a real subdirectory created under `/mnt` triggers the warning; a
directory on the Linux filesystem passes. A real
`nix build .#homeConfigurations.current.activationPackage --impure` +
activation confirms it builds and runs correctly in the full `doctor`
output.

**Constraints**: Must not alter the existing `$HOME` check's behavior
or wording.

## Constitution Check

- **Principle I**: no flake inputs.
- **Principle V**: scoped as its own spec/PR.

No violations.

## Project Structure

```text
pkgs/doctor/doctor   # updated: new $PWD-under-/mnt check alongside the existing $HOME one
README.md            # updated: WSL walkthrough callout, mgit section explanation, Health check summary
```
