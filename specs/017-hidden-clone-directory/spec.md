# Feature Specification: Hidden Default Clone Directory

**Feature Branch**: `017-hidden-clone-directory`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "Instead of ~/workspaces-host-v2 use ~/.workspaces-host-v2 to stay out of the way of most directory listings."

## Background

`WORKSPACES_HOST_REPO` (feature 014) defaults to `~/workspaces-host-v2` -
a visible top-level entry in a plain `ls ~`/file-manager listing of the
home directory, alongside a user's actual project folders. Dotting it
(`~/.workspaces-host-v2`) keeps this repository's own clone out of that
listing by default, the same convention `~/.config`, `~/.ssh`, etc.
already follow, without changing anything about how it behaves.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The default clone location doesn't clutter `~` (Priority: P1)

An engineer who just followed the install steps runs `ls ~` and doesn't
see `workspaces-host-v2` sitting alongside their actual project folders -
it's there if they `cd ~/.workspaces-host-v2` or look with `ls -a`, but
out of the way otherwise.

**Independent Test**: Follow README's install steps verbatim; confirm the
clone lands at `~/.workspaces-host-v2`; confirm `WORKSPACES_HOST_REPO`,
`workspaces-host-update`, and the daily sync nudge (feature 014) all
resolve to that same path with no further configuration.

**Acceptance Scenarios**:

1. **Given** a fresh activation, **When** `echo $WORKSPACES_HOST_REPO` is
   run in a real shell, **Then** it prints `<home>/.workspaces-host-v2`.
2. **Given** no `$WORKSPACES_HOST_REPO` override, **When**
   `workspaces-host-update` runs, **Then** it operates on
   `~/.workspaces-host-v2`.
3. **Given** the same default, **When** `doctor` runs, **Then** its
   sandbox-sync check reports on `~/.workspaces-host-v2`.

---

### Edge Cases

- Anyone who already cloned this repo to the old, non-dotted
  `~/workspaces-host-v2` path is unaffected by the code change alone
  (the default only applies where `$WORKSPACES_HOST_REPO` isn't already
  set some other way) - they'd need to either move their clone or set
  `WORKSPACES_HOST_REPO` explicitly to their existing path. This is
  called out in README rather than silently assumed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `home/shell.nix`'s `WORKSPACES_HOST_REPO` default MUST be
  `${config.home.homeDirectory}/.workspaces-host-v2`.
- **FR-002**: `pkgs/workspaces-host-update`'s fallback default MUST match
  (`$HOME/.workspaces-host-v2`).
- **FR-003**: README.md's clone command and every reference to the
  default clone path MUST use the dotted form, with a short, plain-
  language note explaining why it's dotted (for the least-experienced
  audience this document targets).
- **FR-004**: Prior specs (014) that documented the old default MUST be
  updated to reflect the new one, per this repo's own "don't let specs
  drift" convention - excluding verbatim quotes of a user's original
  request, which are a historical record, not a statement of current
  behavior.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix build .#homeConfigurations.default.activationPackage`
  succeeds with the new default.
- **SC-002**: A real activation's `$WORKSPACES_HOST_REPO` resolves to the
  dotted path; `workspaces-host-update` and `doctor` operate on it
  without any override.
- **SC-003**: `nix flake check --all-systems` continues to pass.

## Assumptions

- No migration tooling is added for engineers already on the old,
  non-dotted default - this is a new-default change, not a breaking
  change to an existing installation's actual files (their clone still
  works exactly as before at its current path; only a *fresh* install
  following the current README lands at the new path).
