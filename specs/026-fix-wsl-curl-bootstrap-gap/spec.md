# Feature Specification: Fix the curl Bootstrap Gap on Fresh WSL Debian

**Feature Branch**: `026-fix-wsl-curl-bootstrap-gap`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User-reported bug: "In a fresh WSL Debian `curl` does not
exist, so this will not work as the first step: `sh -c "$(curl -fsSL
https://raw.githubusercontent.com/intellectual-frontiers/workspaces-host-v2/main/install.sh)"`"

## Background

`install.sh` (feature 020) auto-installs `curl`/`git` if missing as its
own first internal step - but that logic can only run *after*
`install.sh` itself has been fetched, and fetching it is exactly what
the README's documented one-liner used `curl` for. On a genuinely fresh
WSL Debian image (confirmed directly by the user, not assumed), `curl`
isn't present, so the one-liner the README told people to run as their
very first command couldn't even start - a real chicken-and-egg gap in
exactly the path the README calls out as "what most people reading this
want."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The documented first command actually works on a fresh WSL Debian image (Priority: P1)

**Independent Test**: On a WSL Debian image with neither `curl` nor
`git` present, copy-paste the README's documented step-4 command
verbatim; confirm it succeeds without any prior manual step.

**Acceptance Scenarios**:

1. **Given** a fresh WSL Debian image with no `curl`/`git`, **When** the
   engineer runs the README's documented step-4 command, **Then** it
   installs `curl`/`git` via `apt-get` first, then fetches and runs
   `install.sh` successfully.
2. **Given** `curl`/`git` are already present (a re-run, or a less
   minimal image), **When** the same command runs, **Then** the
   `apt-get install` step is a harmless no-op and the rest proceeds
   identically.

---

### Edge Cases

- The fix must not silently assume `curl`/`git` are missing only on
  WSL - the same gap can exist on a genuinely minimal Linux VM/cloud
  image. "Other platforms" now says explicitly: check `curl -V`, and if
  missing, install it with the correct package manager for that
  distro family (`apt-get`/`dnf`/`pacman`) before running the one-liner.
- macOS always ships `curl`/`git`, and has no `apt-get`/`dnf`/`pacman` -
  the fix must not suggest a Debian-specific prefix there.
- `install.sh` itself needed no code change - its own internal
  prerequisite-install logic (auto-sensing Debian/RHEL/Arch families)
  was already correct; the bug was entirely in what the README told
  people to run *before* that logic could ever execute.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Windows/WSL walkthrough's documented first command
  MUST install `curl`/`git` via `apt-get` before attempting to fetch
  `install.sh`, as a single copy-pasteable line.
- **FR-002**: "Other platforms" MUST NOT claim the exact same command is
  usable unchanged across Linux and macOS - it MUST distinguish: Linux
  families needing their own package manager's equivalent prefix if
  `curl` is missing, versus macOS, which never needs one.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The documented command is syntax-valid under both `sh -n`
  and `dash -n`.
- **SC-002**: No stale copy of the old, unprefixed one-liner remains
  anywhere in the README.

## Assumptions

- No `install.sh` code change is required - this is a documentation-only
  fix for the bootstrap command shown to a user before `install.sh` can
  run at all.
