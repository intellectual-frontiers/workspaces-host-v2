# Implementation Plan: Fix the xz Bootstrap Gap on Fresh Linux Installs

**Branch**: `027-fix-xz-bootstrap-gap` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Extend `install.sh`'s existing `install_prereqs_linux` function (and the
parallel macOS check) to also detect and install `xz` - required by the
official Nix installer to unpack its own binary tarball - using the
correct package name per distro family (`xz-utils` on Debian/Ubuntu,
`xz` on RHEL/Fedora/CentOS and Arch).

## Technical Context

**Language/Version**: POSIX `/bin/sh` (`install.sh`).

**Primary Dependencies**: None new.

**Testing**: `sh -n`/`dash -n` syntax check; the distro-family `case`
statement's matching logic tested in isolation for all four branches
(an in-process test of the real function initially gave misleading
results because it sources this actual sandbox's own `/etc/os-release`,
overriding a test-injected `ID` - a test-harness artifact, not a defect
in the script, confirmed by re-testing the bare `case` logic directly
with synthetic `family` strings for every branch).

**Constraints**: No README change - this is purely `install.sh`'s own
internal prerequisite-detection concern, unlike feature 026's fix.

## Constitution Check

- **Principle I**: no flake/code changes beyond `install.sh` itself; no
  new dependency.
- **Principle V**: scoped as its own spec/PR, immediately following
  feature 026's related but distinct fix.

No violations.

## Project Structure

```text
install.sh   # updated: install_prereqs_linux and the Darwin branch also check/install xz
```
