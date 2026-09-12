# Feature Specification: Credentials UX Polish

**Feature Branch**: `025-credentials-ux-polish`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "The ~/.config/workspaces-host/credentials
should already be created after install and move the credentials
instructions right after installation in the README since it's
necessary to usually run. Also, explain in the README how to setup
config vars using direnv so that if env vars are being passed in from a
container or CI/CD it uses those as the default but if defaults are not
available, it uses `(cat
~/.local/state/workspaces-host/secrets/env/AWS_ACCESS_KEY_ID)`. New
engineers and people who are new to coding won't know that their code
sometime will run in CI/CD, others local, etc."

## Background

Feature 024 made credentials onboarding one plain file + one command,
but two rough edges remained: `install.sh` didn't create the
credentials file itself (an engineer had to run `workspaces-host-update`
once just to get the template, then again to apply it - two round
trips instead of one), and the README buried "Setting up your
credentials" deep in the document, well after several other sections an
engineer doesn't need yet. Separately, this repo's own `.envrc`
examples showed the simplest form of reading a locally-configured
secret, without addressing the very common real-world case of the same
project also running in CI/CD or a container, where the platform itself
already injects the credential as an environment variable - a beginner
who has never thought about "where does my code actually run" has no
way to know a naive `.envrc` would silently overwrite a CI-injected
secret with their own local one.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The credentials file already exists right after install (Priority: P1)

**Independent Test**: Run `install.sh` against a fresh `$HOME`; confirm
`~/.config/workspaces-host/credentials` exists (mode 600, matching the
tracked template) the moment the script finishes, with no additional
command needed to create it.

**Acceptance Scenarios**:

1. **Given** a fresh install, **When** `install.sh` finishes, **Then**
   `~/.config/workspaces-host/credentials` already exists at mode 600.
2. **Given** the file already exists (a re-run, or an upgrade from
   before this feature), **When** `install.sh` runs again, **Then** it
   leaves the existing file untouched (no overwrite of anything the
   engineer already filled in).

---

### User Story 2 - Credentials setup is one of the first things an engineer sees (Priority: P1)

**Independent Test**: Read the README top to bottom; confirm "Setting
up your credentials" appears immediately after the Installation section
and before any unrelated topic (mgit, PostgreSQL, compliance tooling,
etc.).

**Acceptance Scenarios**:

1. **Given** the README's table of sections, **When** read in order,
   **Then** "Setting up your credentials" (and its subsections) is the
   first `##` heading after "Installation".
2. **Given** every cross-reference to a relocated section, **When**
   read, **Then** each correctly says "above" or "below" for the
   section's new position (no stale directional reference left behind).

---

### User Story 3 - A `.envrc` example that's actually safe to copy into a real project (Priority: P1)

An engineer new to programming doesn't yet know that the exact same
project code typically runs in more than one place (their machine, a
teammate's machine, an automated CI/CD pipeline, a container), each of
which gets its secrets differently.

**Independent Test**: Follow the README's `.envrc` example inside a
shell with the target variable already set (simulating CI/CD/a
container); confirm the already-set value wins. Repeat with the
variable unset and the local secrets file present; confirm the local
value is used instead.

**Acceptance Scenarios**:

1. **Given** `$AWS_ACCESS_KEY_ID` already set in the environment (as a
   CI/CD platform or container orchestrator would set it), **When** the
   documented `.envrc` line runs, **Then** the already-set value is used
   unchanged, and the local secrets file is never even read.
2. **Given** `$AWS_ACCESS_KEY_ID` unset locally but present at
   `~/.local/state/workspaces-host/secrets/env/AWS_ACCESS_KEY_ID`,
   **When** the documented `.envrc` line runs, **Then** that file's
   value is used.
3. **Given** neither is present, **When** the documented `.envrc` line
   runs, **Then** the variable is empty with no error.

---

### Edge Cases

- `install.sh`'s credentials-file bootstrap must be idempotent - never
  overwrite an existing file, so re-running the installer (its whole
  design point, per its own header comment) never clobbers values an
  engineer already filled in.
- The `${VAR:-$(cmd)}` shell idiom the README recommends must be
  verified, not assumed, to skip evaluating the fallback command
  entirely when the variable is already set - the whole safety argument
  ("CI/CD's own secret wins, unconditionally") depends on this being
  true.
- Moving the credentials section earlier in the README changes several
  "see X above/below" cross-references; every one must be checked, not
  just the ones inside the moved block itself (a reference *to* the
  moved section, from a part of the document that didn't move, also
  needs re-checking).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `install.sh` MUST create
  `~/.config/workspaces-host/credentials` from the tracked
  `credentials.example` (mode 600) if it doesn't already exist, and
  MUST NOT touch it if it does.
- **FR-002**: README's "Setting up your credentials" section (and its
  subsections) MUST appear immediately after the "Installation" section
  and its platform-specific subsections, before any other topic.
- **FR-003**: The Windows and "Other platforms" walkthroughs, and the
  manual "What the installer actually does" section, MUST reflect the
  new step ordering and describe the credentials file as already
  present by the time installation finishes.
- **FR-004**: README MUST document the `${VAR:-$(cat
  .../secrets/env/VAR)}` pattern for a project's `.envrc`, explaining
  why the already-set-wins order matters for code that runs in both a
  developer's sandbox and CI/CD or a container.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A real, isolated test of `install.sh`'s new bootstrap
  step confirms first-run creation and idempotent re-run (no
  overwrite).
- **SC-002**: A real shell test confirms the recommended `.envrc`
  pattern behaves correctly in all three states (already-set, local
  fallback, neither) and that the fallback command is never invoked
  when the variable is already set.
- **SC-003**: Every relocated or newly-forward/backward-pointing
  cross-reference in the README was checked by hand and reads
  correctly.
- **SC-004**: `nix flake check --all-systems` continues to pass (no Nix
  module changed by this feature, but verified anyway).

## Assumptions

- No Nix module changes are required for this feature - it is purely
  `install.sh` and documentation.
- `workspaces-host-update`'s own first-run bootstrap (built in feature
  024) remains as a fallback for anyone who reaches it without having
  gone through `install.sh` (a manual install that skipped that step,
  or a deleted credentials file).
