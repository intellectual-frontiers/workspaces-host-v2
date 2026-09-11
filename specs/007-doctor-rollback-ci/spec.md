# Feature Specification: Doctor + Rollback + CI

**Feature Branch**: `007-doctor-rollback-ci`

**Created**: 2026-09-11

**Status**: Draft

**Input**: User description: "Doctor + rollback + CI: a slim doctor health-check command, documented home-manager generation rollback, and a GitHub Actions workflow running nix flake check plus the OCI build"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One command reports whether the environment is healthy (Priority: P1)

An engineer (or an AI agent, via the session-start hook from Phase 3) runs
`doctor` and gets a clear PASS/WARN/FAIL report of whether Nix, the
shell/prompt/direnv stack, git, and every ported CLI tool are actually
present and working - with a non-zero exit only on a real FAIL, not on
merely-informational gaps (like an unset git identity).

**Why this priority**: This is the concrete, user-facing deliverable of
the phase - "doctor" as a name promises exactly this, and it's usable the
moment it exists, independent of the other two legs (rollback, CI).

**Independent Test**: Run `doctor` against a freshly-activated profile
and confirm every check PASSes; run it with an artificially broken `PATH`
and confirm it reports FAIL and exits non-zero.

**Acceptance Scenarios**:

1. **Given** a freshly-activated `default` profile, **When** `doctor`
   runs, **Then** every check reports PASS (or, for a machine-specific
   soft gap like an unset git identity, WARN) and the command exits 0.
2. **Given** an environment missing a required tool, **When** `doctor`
   runs, **Then** the missing tool is reported FAIL and the command exits
   non-zero.
3. **Given** `doctor` itself, **When** built, **Then** it is NOT wrapped
   with a fixed `PATH` the way this repo's other `pkgs/*` tools are -
   doctor's entire purpose is reporting on the *caller's* live
   environment, and wrapping it would make every check pass
   unconditionally regardless of reality.

---

### User Story 2 - Rolling back is a documented, zero-new-tooling operation (Priority: P2)

An engineer who applied a bad change re-activates a previous
home-manager generation and gets their exact prior environment back - no
custom rollback tool, no manual dotfile restoration.

**Why this priority**: The roadmap explicitly frames this as "free with
Nix, unlike chezmoi's forward-only apply" - the deliverable is proving
and documenting that home-manager's own generation mechanism already
does this, not building new tooling on top of it.

**Independent Test**: Activate profile A, then profile B (which changes
something observable), then re-activate A's own generation path and
confirm B's change is gone.

**Acceptance Scenarios**:

1. **Given** two successive activations (each recorded as a
   `home-manager generations` entry), **When** the earlier generation's
   own store path is re-activated, **Then** the environment matches that
   earlier generation exactly (the later generation's changes are
   reverted).

---

### User Story 3 - CI verifies reproducibility, not just asserts it (Priority: P1)

A pull request against this repository automatically runs `nix flake
check` and builds both OCI images (Phase 2's `oci-image`, Phase 5's
`oci-image-sandboxed`) in GitHub Actions, so a broken flake is caught
before merge rather than discovered by the next engineer who happens to
run it locally.

**Why this priority**: Every phase so far has been verified manually, in
this session, against this sandbox - CI is what makes that verification
durable and automatic for every future change, which is squarely a P1
concern for a repository whose entire premise is reproducibility.

**Independent Test**: Open a pull request and confirm the workflow runs
and its steps (`nix flake check`, both OCI image builds, `doctor` against
a real activation) all complete.

**Acceptance Scenarios**:

1. **Given** a pull request against `main`, **When** GitHub Actions
   runs the `CI` workflow, **Then** `nix flake check --all-systems`,
   both OCI image builds, and a `doctor` run against a real activation
   all succeed.

---

### Edge Cases

- What happens if `doctor` runs somewhere Nix was never installed at
  all? The very first check (`nix` on `PATH`) fails, and every subsequent
  check that would otherwise depend on Nix having run still runs
  independently (checking `PATH` directly) - `doctor` doesn't abort early
  on the first failure, so an engineer gets the *full* picture in one run
  rather than fixing issues one `doctor` invocation at a time.
- What happens to old generations over time (disk usage)? Out of scope
  for this feature - `nix-collect-garbage` (or `home-manager expire-
  generations`) is the existing, standard Nix answer, not something this
  feature needs to reinvent.
- Why isn't there a `workspaces-host rollback` command? Because
  `home-manager generations` (list) plus re-running `<path>/activate`
  (or, on recent home-manager versions, `home-manager generations` even
  prints a ready-to-paste command) already *is* the rollback mechanism -
  adding a wrapper around it would be exactly the kind of unnecessary
  abstraction Constitution Principle V-adjacent minimalism argues
  against. This feature documents the existing mechanism.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The flake MUST provide a `doctor` command
  (`packages.<system>.doctor`, included in `home.packages`) that checks:
  `nix` on `PATH` and flakes/nix-command enabled; `home-manager` on
  `PATH`; `fish`/`oh-my-posh`/`direnv` on `PATH` and the nix-direnv
  integration file present; `git` on `PATH` and identity configured
  (WARN, not FAIL, if unset); every ported tool from Phases 1-4
  (`semtag`, `mgitstatus`, `git-standup`, `specify`, `backlog`,
  `scaffold-agent-harness`, `sensitivectl`) on `PATH`; `docker` on `PATH`
  (WARN only - optional, for running the OCI images).
- **FR-002**: `doctor` MUST print one PASS/WARN/FAIL line per check, run
  every check regardless of earlier failures, and exit non-zero if and
  only if at least one check FAILed.
- **FR-003**: `doctor` MUST NOT be wrapped with a fixed `PATH` at
  packaging time - it must observe the caller's actual environment.
- **FR-004**: This feature MUST document (README and/or
  `quickstart.md`) that rolling back is: list generations
  (`home-manager generations`), then re-run the desired generation's own
  `activate` script - verified against a real two-generation
  activate/rollback cycle during implementation, not merely described.
- **FR-005**: The repository MUST include a GitHub Actions workflow
  (`.github/workflows/ci.yml`) triggered on push to `main` and on every
  pull request, running `nix flake check --all-systems`, building
  `packages.x86_64-linux.oci-image` and
  `packages.x86_64-linux.oci-image-sandboxed` explicitly, and running
  `doctor` against a real activation of `homeConfigurations.default`.

### Key Entities

- **`doctor`**: the health-check command.
- **Home-manager generation**: home-manager's own existing, pre-built
  mechanism this feature documents rather than wraps.
- **CI workflow**: `.github/workflows/ci.yml`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `doctor` run against a freshly-activated profile reports
  all PASS (or WARN for machine-specific gaps) and exits 0.
- **SC-002**: A real two-generation activate/rollback cycle (verified
  during implementation) shows the earlier generation's state correctly
  restored after re-activating its path.
- **SC-003**: The CI workflow's steps all pass on a real pull request
  against this repository.
- **SC-004**: `nix flake check --all-systems` continues to pass with
  `doctor` added (cross-platform, unlike Phase 5's Linux-only additions).

## Assumptions

- CI runs on GitHub-hosted `ubuntu-latest` runners, which have
  unrestricted internet access - the `git+https` flake-input workaround
  this repository's *development sandbox* needed (see Phase 1's plan.md)
  is not needed in CI and isn't specific to it; it was purely this
  session's own sandbox constraint.
- `doctor`'s check list matches what Phases 1-4 actually ship; a future
  phase adding a new default tool extends `doctor`'s list in the same
  small PR, not as a follow-up.
