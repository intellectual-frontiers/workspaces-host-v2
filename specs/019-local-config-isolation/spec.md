# Feature Specification: Local Configuration Isolation & Real-Identity Profiles

**Feature Branch**: `019-local-config-isolation`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "Make sure that whatever a developer needs to modify never impacts the core code in this repo; meaning, anything that's configured is always local and never conflicts with code in the GitHub repo. OK with the impure per-user flake output as the fix for the hardcoded-username problem."

## Background

Two related, previously-undiscovered problems surfaced while planning a
one-step installer:

1. `flake.nix` hardcodes `home.username = "workspace"` /
   `home.homeDirectory = "/home/workspace"` for every profile including
   `default`. Home-manager's activation script refuses to run unless the
   real `$USER`/`$HOME` match that literal - so a real person whose
   actual username isn't "workspace" hits `Error: USER is set to <you>
   but we expect workspace` and is stuck. This was masked throughout
   earlier development by manually forcing `USER=workspace
   HOME=/home/workspace` during testing.
2. The previously-documented way to set your git identity (`sed`-editing
   the tracked `home/git.nix` directly, from feature 016) is itself a
   core-repo-file edit - the next `workspaces-host-update`'s `git pull
   --ff-only` would refuse (or, worse, silently conflict) the moment
   upstream touched that same file, which is exactly the kind of
   local-vs-core conflict this feature exists to prevent.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Activation works with your actual username (Priority: P1)

An engineer whose real OS username isn't "workspace" runs the documented
install steps and it just works - no manual `USER`/`HOME` juggling, no
forking `flake.nix`.

**Independent Test**: Build and activate `homeConfigurations.current`
(and one `current-<persona>`) as a real, arbitrary user (not "workspace")
and confirm activation succeeds and files land in that user's actual home
directory.

**Acceptance Scenarios**:

1. **Given** a real user whose username is, say, `root` (or any name
   other than "workspace"), **When** `nix build
   .#homeConfigurations.current.activationPackage --impure` then
   `./result/activate` run, **Then** activation succeeds and home files
   land in that user's real `$HOME`.
2. **Given** the same machine, **When** `nix flake check --all-systems`
   runs (no `--impure`), **Then** it still passes unchanged - `default`,
   every per-system profile, and every plain persona profile keep the
   fixed "workspace" test identity, completely unaffected by this
   feature.
3. **Given** a persona (e.g. `backend`), **When** built as
   `current-backend` instead, **Then** it also resolves to the real
   user's identity, not "workspace".

---

### User Story 2 - Personal overrides never touch a repo file (Priority: P1)

An engineer sets their git identity (or declares a real secret) without
editing any file inside this repository - so `git pull`/
`workspaces-host-update` can never conflict with or overwrite it.

**Independent Test**: Create `~/.config/workspaces-host/local.nix` with a
git identity override; activate; confirm the override takes effect;
confirm `nix flake check` (pure) is completely unaffected by the file's
presence or absence.

**Acceptance Scenarios**:

1. **Given** `~/.config/workspaces-host/local.nix` declaring
   `programs.git.userName`/`userEmail`, **When** any profile is built
   with `--impure` and activated, **Then** the generated git config
   reflects those values instead of the placeholder defaults.
2. **Given** no such file exists, **When** any profile is built and
   activated (with or without `--impure`), **Then** nothing errors and
   the placeholder defaults apply, exactly as before this feature.
3. **Given** `nix flake check` (pure, no `--impure`), **When** it runs,
   **Then** `local.nix`'s presence or absence has zero effect - the
   lookup silently no-ops under pure evaluation.
4. **Given** `home/git.nix`'s `userName`/`userEmail`, **When** inspected,
   **Then** they're declared with `lib.mkDefault`, so `local.nix` can
   override them with a plain, non-conflicting definition.

---

### Edge Cases

- `$USER` is not guaranteed to be set even in real shells (observed
  directly: this project's own dev sandbox has `$HOME` but not `$USER`
  exported) - `pkgs/workspaces-host-update` defensively falls back to
  `whoami` before relying on it; README's install steps should carry the
  same defensiveness if scripted (addressed fully in the installer
  feature).
- A gitignored file *inside* this repository would NOT actually work for
  this purpose: a flake evaluated from a git checkout only ever sees
  git-tracked content (confirmed by testing - Nix's git-tree source copy
  excludes untracked/gitignored files even when present on disk), so the
  override file must live outside the repository entirely
  (`~/.config/workspaces-host/local.nix`), not merely `.gitignore`d
  inside it.
- A real infinite-recursion bug was hit and fixed during implementation:
  computing a module's own `imports` list using `pkgs.lib.optional`
  inside a module that itself takes `{ pkgs, ... }` as an argument
  creates a genuine circular dependency in the module system (`pkgs`
  can't be resolved until `imports` is, and `imports` here needed
  `pkgs`). Fixed by using a plain `if/then/else` list expression instead,
  which doesn't touch the `pkgs` argument while computing `imports`.
- `local.nix`'s dynamically-computed path must be coerced to an actual
  Nix path value (`/. + "string"`), not left as a plain string - a raw
  string in a module's `imports` list does not behave the same as a path.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `flake.nix` MUST provide `homeConfigurations.current` and
  `homeConfigurations."current-<persona>"` (one per entry in
  `personaModules`), each using `builtins.getEnv "USER"`/`"HOME"` and
  `builtins.currentSystem` for identity, requiring `--impure` to build.
- **FR-002**: Every existing `homeConfigurations.*` attribute
  (`default`, per-system, plain persona names) MUST remain byte-for-byte
  unchanged in behavior - fixed "workspace" identity, fully pure,
  untouched by `nix flake check`.
- **FR-003**: `home/default.nix` MUST import
  `~/.config/workspaces-host/local.nix` if (and only if) it exists,
  using a mechanism that does not create a circular module-argument
  dependency and does not affect pure evaluation.
- **FR-004**: `home/git.nix`'s `userName`/`userEmail` MUST use
  `lib.mkDefault` so `local.nix` can override them without a Nix
  "conflicting definition" error.
- **FR-005**: A tracked `local.nix.example` at the repo root MUST
  demonstrate the format (git identity override + a commented-out
  secrets declaration).
- **FR-006**: `pkgs/workspaces-host-update` MUST default
  `WORKSPACES_HOST_PROFILE` to `current`, pass `--impure`, and
  defensively set `$USER` via `whoami` if unset.
- **FR-007**: `pkgs/doctor/doctor` MUST report whether
  `~/.config/workspaces-host/local.nix` exists, and MUST distinguish "git
  email unset" from "git email is still the unchanged placeholder"
  (`*@example.invalid`) as two different warnings.
- **FR-008**: README.md MUST document `current`/`--impure` as the real
  install path (updating the WSL walkthrough, the macOS section - which
  simplifies, since `current` auto-senses the system - and the sync
  section), and MUST replace the previous `sed`-the-tracked-file git
  identity instructions with the `local.nix` approach.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix build .#homeConfigurations.current.activationPackage
  --impure` succeeds and activates correctly as a real, non-"workspace"
  user (verified directly in this project's own dev sandbox, not
  assumed).
- **SC-002**: `nix flake check --all-systems` (no `--impure`) continues
  to pass, unchanged.
- **SC-003**: A real `local.nix` with a git identity override produces
  the expected `~/.config/git/config` content, verified by inspecting
  the actual generated file after activation.
- **SC-004**: `doctor` correctly distinguishes an empty git email from a
  still-placeholder one, verified against both real states.

## Assumptions

- `~/.config/workspaces-host/` is the chosen location for `local.nix`
  (and any secrets files referenced from it) - XDG-config-like, doesn't
  collide with anything else this repo manages.
- Persona + real-identity support (`current-<persona>`) is included now
  rather than deferred, since leaving personas broken for anyone not
  literally named "workspace" would be an inconsistent half-fix.
