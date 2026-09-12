# Feature Specification: Detect the Current Directory Under /mnt, Not Just $HOME

**Feature Branch**: `028-doctor-cwd-mnt-check`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User report: "I'm getting a warning like this in WSL: 'using
an I/O intensive operation like git in WSL...', what should I do?
should we give better instructions in the README?"

## Background

`doctor` already warned when `$HOME` was under `/mnt` (feature 021),
but that only catches a misconfigured home directory - it says nothing
about a specific *project* repo an engineer cloned or opened directly
under `/mnt/c/Users/...` (a habit left over from before WSL, or a
folder opened straight from Windows Explorer/VS Code), which is exactly
what triggers WSL's own "I/O intensive operation like git" performance
warning in practice. The README also never explained *why* `~/workspaces`
matters for WSL users specifically, or what to do if this warning
appears.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - doctor catches a slow-filesystem repo, not just a slow-filesystem $HOME (Priority: P1)

**Independent Test**: Run `doctor` from a directory under `/mnt` on
WSL; confirm it warns specifically about the current directory (not
just `$HOME`), naming `/mnt` as the cause and `~/workspaces`/`mgit` as
the fix. Run it from a directory on the Linux filesystem; confirm it
passes.

**Acceptance Scenarios**:

1. **Given** WSL and a current directory under `/mnt`, **When** `doctor`
   runs, **Then** it warns about the current directory specifically,
   distinct from (and in addition to) its existing `$HOME` check.
2. **Given** WSL and a current directory on the Linux filesystem,
   **When** `doctor` runs, **Then** it passes both the `$HOME` and
   current-directory checks.
3. **Given** not running under WSL at all, **When** `doctor` runs,
   **Then** neither check runs (unchanged from before - both are nested
   inside the existing `grep -qi microsoft /proc/version` guard).

---

### Edge Cases

- The new check is purely additive next to the existing `$HOME` check -
  same guard, same `/mnt/*` pattern, just a second independent `case`
  against `$PWD`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `pkgs/doctor/doctor` MUST check whether `$PWD` (not just
  `$HOME`) is under `/mnt` when running under WSL, warning with the
  same explanation and remedy (move to `~/workspaces`) as the existing
  `$HOME` check.
- **FR-002**: README MUST explain, in the WSL walkthrough and in the
  `mgit` section, why `~/workspaces` matters for performance (not just
  organization) on WSL, and what the WSL "I/O intensive operation like
  git" warning means and how to fix it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The new check verified in both states for real: a
  directory under `/mnt` warns; a directory on the Linux filesystem
  passes.
- **SC-002**: `sh -n`/`dash -n` syntax validity maintained.
- **SC-003**: A real build + activation + `doctor` run confirms the new
  check appears correctly in context alongside the existing checks.

## Assumptions

- No change to the existing `$HOME` check - this is purely additive.
