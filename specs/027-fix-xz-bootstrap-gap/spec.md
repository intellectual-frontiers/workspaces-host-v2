# Feature Specification: Fix the xz Bootstrap Gap on Fresh Linux Installs

**Feature Branch**: `027-fix-xz-bootstrap-gap`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User-reported error while running `install.sh` on a fresh WSL
Debian image, right after feature 026 fixed the `curl` gap: "you do not
have 'xz' installed, which I need to unpack the binary tarball" (from
the official Nix installer).

## Background

Feature 026 fixed the README's bootstrap command so `curl`/`git` get
installed before `install.sh` is even fetched. But `install.sh`'s own
prerequisite step (`install_prereqs_linux`) only ever checked for
`curl`/`git` - not `xz`, which the official Nix installer needs to
unpack its own binary tarball on Linux (`tar` alone can't decompress
`.tar.xz` without it). A genuinely minimal Debian image doesn't ship
`xz` either, so an engineer could get all the way past the `curl` fix
from 026, into the Nix-install step, and hit a second, different
missing-prerequisite error - confirmed directly by the user, not
hypothetical.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - install.sh installs everything the Nix installer itself needs (Priority: P1)

**Independent Test**: On a system with `curl`/`git` present but `xz`
missing, run `install.sh`; confirm it installs `xz` via the correct
package manager for that distro family before invoking the Nix
installer, rather than letting the Nix installer fail partway through.

**Acceptance Scenarios**:

1. **Given** `xz` is missing on a Debian/Ubuntu-family system, **When**
   `install.sh` runs, **Then** it installs the `xz-utils` package
   (which provides the `xz` binary the Nix installer actually looks
   for) alongside `curl`/`git`.
2. **Given** `xz` is missing on a RHEL/Fedora/CentOS or Arch system,
   **When** `install.sh` runs, **Then** it installs the `xz` package via
   `dnf`/`pacman` respectively.
3. **Given** `curl`, `git`, and `xz` are all already present, **When**
   `install.sh` runs, **Then** the prerequisite step is a no-op, exactly
   as before this feature.
4. **Given** macOS, **When** `install.sh` runs, **Then** it checks for
   `xz` the same way it already checks for `curl`/`git`, rather than
   assuming it's present.

---

### Edge Cases

- This is purely an `install.sh` fix, not a README fix (unlike feature
  026): the README's bootstrap one-liner only needs to get `curl`/`git`
  present so it can fetch and run `install.sh` at all; everything else,
  `xz` included, is `install.sh`'s own per-distro-family job once it's
  running.
- The Debian/Ubuntu package name (`xz-utils`) differs from the binary
  name (`xz`) and from the package name on RHEL/Fedora/Arch (`xz`) -
  each branch of the existing distro-family `case` uses the correct
  package name for that family.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `install.sh`'s `install_prereqs_linux` MUST check for
  `xz` in addition to `curl`/`git`, and MUST install it (via the
  correct per-family package name) when missing.
- **FR-002**: The macOS branch MUST check for `xz` the same way it
  already checks for `curl`/`git`, rather than assuming it's present.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `install.sh` remains syntax-valid under `sh -n` and
  `dash -n`.
- **SC-002**: The distro-family `case` statement's matching logic
  verified correct for all four recognized families (Debian/Ubuntu,
  RHEL/Fedora/CentOS, Arch, and the unrecognized-distro fallback).

## Assumptions

- No README change is required - the bootstrap one-liner's job (get
  `curl`/`git` present) is unaffected; `xz` is entirely `install.sh`'s
  own internal concern once it's running.
