# Feature Specification: Workspace Profiles

**Feature Branch**: `006-workspace-profiles`

**Created**: 2026-09-11

**Status**: Draft

**Input**: User description: "Workspace profiles: per-persona flake outputs (backend, data, mobile, agent-ops) layered on the shared base, replacing the old repo's single global Homebrew package list"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A persona profile is the shared base plus a focused extra toolset (Priority: P1)

An engineer doing backend work applies `home-manager switch --flake
.#backend` and gets everything the `default` profile provides (Fish,
oh-my-posh, direnv, git, the ported scripts, specify/backlog-md/
scaffold-agent-harness) *plus* a small set of backend-specific tools
(`psql`, `redis-cli`, `docker-compose`, `http`) - without maintaining a
second, separate list of "everything the base profile also has."

**Why this priority**: This is the entire point of the phase - if a
persona profile duplicates the base instead of layering on it, this
feature has recreated the old repo's single-global-list problem with
extra steps.

**Independent Test**: Apply `.#backend`, confirm both a base-profile tool
(`fish`) and a backend-specific tool (`psql`) resolve on `PATH`; diff
`home.packages` between `.#default` and `.#backend` and confirm the
difference is exactly the backend profile's added packages (nothing
removed, nothing duplicated by a separate re-declaration).

**Acceptance Scenarios**:

1. **Given** a clean checkout, **When** `home-manager switch --flake
   .#backend` is applied, **Then** `fish`, `semtag`, `specify`, and
   `backlog` (all from the shared base) resolve on `PATH`, alongside
   `psql`, `redis-cli`, `docker-compose`, and `http` (backend-specific).
2. **Given** the same setup, **When** compared against `.#data`,
   **Then** `.#data` has `python3`/`uv`/`duckdb` instead of the backend
   set, while still sharing the exact same base tools.

---

### User Story 2 - Four personas ship out of the box (Priority: P2)

An engineer picks whichever of `backend`, `data`, `mobile`, or
`agent-ops` matches their work, without writing a new Nix module first.

**Why this priority**: The roadmap names these four explicitly; having
all four ready (even with modest, honestly-scoped package sets) is what
makes this "shipped," not just "possible."

**Independent Test**: Build `homeConfigurations.<persona>.activationPackage`
for all four names and confirm each succeeds.

**Acceptance Scenarios**:

1. **Given** the flake, **When** `nix build
   .#homeConfigurations.<persona>.activationPackage` is run for each of
   `backend`, `data`, `mobile`, `agent-ops`, **Then** all four succeed.

---

### Edge Cases

- What about mobile development's much heavier native toolchains
  (Android SDK, Xcode)? Explicitly out of scope for the `mobile`
  profile - those are large, licensing-encumbered, and platform-specific
  in ways a single cross-platform Nix module can't cleanly cover. The
  profile ships what *is* cleanly packageable (`adb`/`fastboot` via
  `android-tools`, `watchman`), and engineers still install Android
  Studio/Xcode themselves.
- What happens if two personas are needed at once (e.g. a full-stack
  engineer wants both `backend` and `data`)? Out of scope for this
  feature - each persona is applied as its own independent
  `home-manager` profile/generation; combining two into a single active
  profile would need a small composing module of its own, which nothing
  here prevents an engineer from writing, but this feature doesn't ship
  one.
- Why pin persona configurations to `x86_64-linux` only, like `default`?
  Same rationale Phase 1 already established for `default`: avoiding a
  combinatorial `persona × system` attribute set for a single-default-
  platform repository. An engineer on another platform substitutes that
  system's own attribute name when forking a persona module for it.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The flake MUST expose `homeConfigurations.backend`,
  `.data`, `.mobile`, and `.agent-ops`, each built from the same base
  module set (`./home`) as `homeConfigurations.default`, plus exactly one
  additional persona-specific module.
- **FR-002**: Each persona module (`home/profiles/<name>.nix`) MUST only
  add `home.packages` (or equivalent additive config) - it MUST NOT
  redeclare or override anything the base module set already configures
  (shell, prompt, direnv, git, secrets).
- **FR-003**: `backend`'s persona module MUST add `postgresql`, `redis`,
  `docker-compose`, and `httpie` (providing the `http` command).
- **FR-004**: `data`'s persona module MUST add `python3`, `uv`, and
  `duckdb`.
- **FR-005**: `mobile`'s persona module MUST add `android-tools`
  (`adb`/`fastboot`) and `watchman`.
- **FR-006**: `agent-ops`'s persona module MUST add `gh` and `act`.
- **FR-007**: `nix build .#homeConfigurations.<persona>.activationPackage`
  MUST succeed for all four persona names.

### Key Entities

- **Persona module**: one `home/profiles/<name>.nix` file, adding a
  focused package set on top of the shared base.
- **Persona home configuration**: `homeConfigurations.<name>`, the base
  module set plus exactly one persona module.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All four persona `activationPackage`s build successfully.
- **SC-002**: A real activation of the `backend` persona (verified during
  implementation, not just built) shows both shared-base tools (`fish`,
  `semtag`, `specify`, `backlog`) and backend-specific tools (`psql`,
  `redis-cli`, `docker-compose`, `http`) resolving on `PATH`.
- **SC-003**: `nix flake check --all-systems` continues to pass with the
  four persona modules added.

## Assumptions

- The four persona names and their package sets match the roadmap's own
  examples (`backend`, `data`, `mobile`, `agent-ops`) rather than
  inventing different ones; an engineer needing a fifth persona adds
  `home/profiles/<name>.nix` and one line in `flake.nix`'s
  `personaModules` - a pattern this feature establishes and documents,
  not a closed set.
- Each persona's package list is intentionally modest (3-4 packages) -
  representative and genuinely useful, not an attempt to enumerate every
  tool someone in that role might ever want. Growing a persona's list is
  a routine follow-up change, not a design change.
