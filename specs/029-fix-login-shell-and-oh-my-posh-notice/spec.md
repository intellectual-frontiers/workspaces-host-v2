# Feature Specification: Fix Login Shell Not Switching to fish, and the oh-my-posh Upgrade Nag

**Feature Branch**: `029-fix-login-shell-and-oh-my-posh-notice`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User report after a real install: `$SHELL` was still
`/bin/bash` after `install.sh` finished, requiring typing `fish`
manually every new window, and `oh-my-posh` printed an upgrade nag on
every fish startup. The user asked whether to run `oh-my-posh enable
autoupgrade` as part of installation, and separately whether to keep
`fish` or switch the default shell to `bash`. Also reported: running
`code` inside WSL launches the Windows copy of VS Code instead of a
Linux one.

## Background

home-manager standalone mode cannot manage `/etc/shells`/`/etc/passwd`
itself - this was known and commented in `home/shell.nix`, but nothing
actually acted on it: `install.sh` never ran `chsh`, so a fresh install
left the engineer's login shell exactly as it was before (bash, on a
default Debian/WSL account), silently undermining the "fish is the
default shell" README claim. Separately, oh-my-posh's own binary here
lives in the read-only Nix store - `enable autoupgrade` would fight
that (either fail outright trying to overwrite it, or write a binary
Nix doesn't track), directly contradicting Constitution Principle I
("pinned by lockfile, not resolved against a mutable upstream").

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A fresh install's new terminal windows actually start in fish (Priority: P1)

**Independent Test**: Run `install.sh` end to end on an account whose
shell is bash; confirm `/etc/passwd`'s shell field is updated to fish's
stable home-manager-managed path, without requiring a manual `chsh`.

**Acceptance Scenarios**:

1. **Given** a fresh install where the account's login shell is bash,
   **When** `install.sh` finishes, **Then** `getent passwd $USER`'s
   shell field is `$HOME/.nix-profile/bin/fish` (the stable,
   home-manager-repointed symlink - not the raw, upgrade-fragile
   `/nix/store/...` path underneath it).
2. **Given** the shell is already fish, **When** `install.sh` runs
   again, **Then** the `chsh` step is a no-op.
3. **Given** `chsh`/`/etc/shells` can't be modified (no `sudo`, a
   locked-down `/etc`), **When** `install.sh` runs, **Then** it warns
   and continues rather than aborting the whole install - fish still
   works typed by hand, and `doctor` now checks this so it's never a
   silent gap.

---

### User Story 2 - doctor reports the real login shell, not just fish's presence (Priority: P1)

**Independent Test**: With the login shell set to bash, run `doctor`;
confirm it warns specifically about the login shell (distinct from
"fish is on PATH," which was already a separate, passing check). Set it
to fish; confirm it passes.

**Acceptance Scenarios**:

1. **Given** the login shell (per `/etc/passwd`, not `$SHELL`) isn't
   fish, **When** `doctor` runs, **Then** it warns with the exact `chsh`
   command to fix it.
2. **Given** the login shell is fish, **When** `doctor` runs, **Then**
   it passes.

---

### User Story 3 - The oh-my-posh update nag is silenced without fighting Nix (Priority: P1)

**Independent Test**: Activate a profile; confirm the generated
oh-my-posh config includes `disable_notice: true`, and that the
checked-in theme file (`themes/oh-my-posh/coach.omp.json`, ported
byte-for-byte in feature 008) is untouched.

**Acceptance Scenarios**:

1. **Given** a fresh activation, **When** the generated
   `~/.config/oh-my-posh/config.json` is inspected, **Then** it
   contains `"disable_notice": true`.
2. **Given** the same activation, **When** `themes/oh-my-posh/coach.omp.json`
   is diffed against its committed version, **Then** there is no
   difference - the override is merged in at the Nix level, not edited
   into the source file.

---

### Edge Cases

- `oh-my-posh enable/disable notice`'s CLI toggle is reported unreliable
  upstream (multiple open GitHub issues); the config-file key
  (`disable_notice`) is used directly instead, per oh-my-posh's own FAQ.
- `oh-my-posh enable autoupgrade` was explicitly considered and
  rejected: the binary lives in the read-only Nix store, so a
  self-upgrade would either fail or write an untracked binary outside
  Nix's model entirely - a newer oh-my-posh here means bumping this
  flake's nixpkgs pin, like any other tool.
- The `code` (VS Code) issue reported alongside this is **not** a bug
  in this repo - nothing here installs or manages VS Code. Running
  `code` inside WSL and reaching Windows' own copy is WSL's designed
  behavior (Windows' `$PATH` is appended into WSL's); the correct fix is
  installing the "WSL" extension in Windows-side VS Code, which is
  documented in README rather than "fixed" in code, since there's
  nothing in this repo to change.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `install.sh` MUST attempt to set the login shell to
  `$HOME/.nix-profile/bin/fish` (registering it in `/etc/shells` first
  if needed) once fish exists on disk, as a best-effort step that warns
  rather than aborts on failure.
- **FR-002**: `pkgs/doctor/doctor` MUST check the actual login shell
  (via `getent passwd`, not `$SHELL`) against fish's stable path,
  independent of its existing "is fish on PATH" check.
- **FR-003**: `home/shell.nix` MUST merge `disable_notice = true;` into
  `programs.oh-my-posh.settings` without modifying the checked-in theme
  file.
- **FR-004**: README MUST document: the automatic `chsh` and its
  fallback, why `enable autoupgrade` was rejected, and how to correctly
  use VS Code with this setup on WSL.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The `chsh` logic verified for real against this sandbox's
  actual root account: bash to fish, idempotent re-run, restored
  afterward.
- **SC-002**: `doctor`'s new login-shell check verified in both states
  for real.
- **SC-003**: A real build + activation confirms `disable_notice: true`
  in the generated config and zero diff on the checked-in theme file.
- **SC-004**: `sh -n`/`dash -n` syntax validity maintained on
  `install.sh` and `pkgs/doctor/doctor`.
- **SC-005**: `nix flake check --all-systems` continues to pass.

## Assumptions

- Switching the default shell away from fish entirely (to bash) was
  raised as an open question, not decided here - see the plan's
  discussion. This feature only fixes fish actually taking effect as
  configured; it doesn't change which shell is configured.
