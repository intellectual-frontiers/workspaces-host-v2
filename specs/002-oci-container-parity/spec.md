# Feature Specification: Container/OCI Parity

**Feature Branch**: `002-oci-container-parity`

**Created**: 2026-09-11

**Status**: Draft

**Input**: User description: "Container/OCI parity: build an OCI image from the same flake outputs as the core home-manager profile so a WSL host, CI, and a cloud agent-harness container share one closure"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One command produces a runnable container with the same toolset (Priority: P1)

An engineer (or CI) runs a single `nix build` command against this
repository and gets an OCI image tarball that, when loaded into Docker (or
any OCI-compatible runtime) and run, provides the same shell, prompt,
git configuration, and CLI toolset as `home-manager switch --flake
.#default` provides on a host — built from the exact same evaluated
home-manager module set, not a hand-maintained Dockerfile that could drift.

**Why this priority**: This is Phase 2's whole reason to exist per the
roadmap ("solves works in my sandbox, not in the harness's container").
Nothing else in this feature matters if the image doesn't actually share
the closure.

**Independent Test**: Run `nix build .#packages.x86_64-linux.oci-image`,
`docker load -i result`, then `docker run --rm workspaces-host:latest
fish -c 'fish --version; git config --get user.name; oh-my-posh --version'`
and confirm all three succeed with the same values Phase 1's quickstart
documents for the host profile.

**Acceptance Scenarios**:

1. **Given** a clean checkout, **When** an engineer runs `nix build
   .#packages.<system>.oci-image`, **Then** the build succeeds and
   produces a loadable OCI image tarball with no separate Dockerfile or
   manual `docker build` step involved.
2. **Given** the image is loaded and run, **When** the engineer inspects
   the container's `PATH`, **Then** `fish`, `oh-my-posh`, `direnv`, `git`,
   and the three ported scripts (`semtag`, `mgitstatus`, `git-standup`)
   all resolve, matching Phase 1's host profile package set exactly
   (both are built from `config.home.packages` of the same
   `homeConfigurations` evaluation).
3. **Given** the image is run, **When** the engineer inspects
   `~/.config/git/config` inside the container, **Then** it is
   byte-identical in content to the one Phase 1 generates on a host
   (same declarative git identity/aliases/defaults).

---

### User Story 2 - Image builds without a running container runtime (Priority: P2)

A CI runner (or a developer machine) that has Nix but no Docker daemon can
still evaluate and build the OCI image derivation - only *running* it
requires a container runtime.

**Why this priority**: Keeps the image buildable as part of `nix flake
check`-driven CI without requiring privileged Docker-in-Docker in every
environment; running/smoke-testing the image is a separate, optional step.

**Independent Test**: With `docker` uninstalled or unreachable, run `nix
build .#packages.x86_64-linux.oci-image` and confirm it still succeeds
(the derivation itself has no runtime dependency on a container engine).

**Acceptance Scenarios**:

1. **Given** no container runtime is available, **When** `nix build
   .#packages.x86_64-linux.oci-image` is run, **Then** it succeeds and
   produces the tarball at `result`.

---

### Edge Cases

- What happens on macOS, where Docker images are still Linux images?
  `dockerTools.buildLayeredImage` evaluates fine for `x86_64-darwin`/
  `aarch64-darwin` (so `nix flake check --all-systems` still passes), but
  actually *building* it there requires a Linux builder (a standard Nix
  cross-building constraint, not something this feature works around).
  This is documented, not silently broken.
- What happens if `home/*.nix` changes in a later phase? The image is
  built directly from `homeConfigurations.<system>.config`, so it picks
  up any change to the shared modules automatically - there's no separate
  package list to keep in sync.
- What happens for tools that need `/bin/sh` or NSS (`/etc/passwd`,
  `/etc/nsswitch.conf`) inside the minimal image? Covered via
  `pkgs.dockerTools.fakeNss` and `pkgs.cacert` in the image contents,
  verified by running `git` (which shells out) and `oh-my-posh` inside
  the built container.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The flake MUST expose an OCI image as
  `packages.<system>.oci-image`, buildable via a plain `nix build`
  invocation with no external Dockerfile.
- **FR-002**: The image's package set MUST be derived from the same
  `homeConfigurations.<system>.config.home.packages` that Phase 1's host
  profile installs, not a separately maintained list.
- **FR-003**: The image MUST include the generated dotfiles (git config,
  fish config, oh-my-posh theme, direnv/nix-direnv integration script)
  produced by the same home-manager module evaluation, placed at their
  equivalent `$HOME`-relative paths under `/root`.
- **FR-004**: The image MUST be runnable as a plain container (`docker
  run ... fish` or `... bash`) without additional setup steps, and must
  resolve `git`, `fish`, `oh-my-posh`, `direnv`, `semtag`, `mgitstatus`,
  and `git-standup` on `PATH`.
- **FR-005**: Building the image derivation MUST NOT require a running
  container engine; only *loading/running* the resulting tarball does.
- **FR-006**: The image MUST include CA certificates (`cacert`) and
  minimal NSS files (`dockerTools.fakeNss`) so that tools performing TLS
  requests or UID/GID lookups (e.g. `git clone https://...`) work inside
  the container without extra configuration.

### Key Entities

- **OCI image derivation**: `packages.<system>.oci-image`, a
  `dockerTools.buildLayeredImage` output built from a given system's
  `homeConfigurations.<system>.config`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix build .#packages.x86_64-linux.oci-image` succeeds on a
  clean checkout and produces a `docker load`-able tarball.
- **SC-002**: After `docker load` + `docker run`, all six tools
  (`fish`, `git`, `oh-my-posh`, `direnv`, `semtag`, `mgitstatus`,
  `git-standup` - seven, matching Phase 1's list) resolve on `PATH` and
  the generated `~/.config/git/config` matches Phase 1's host-profile
  content.
- **SC-003**: `nix flake check --all-systems` continues to pass (evaluate
  cleanly) with the new `oci-image` output added for all four systems.

## Assumptions

- Docker (or another OCI-compatible runtime capable of `docker load`) is
  available wherever the image is actually run; this feature only
  guarantees the image *builds* without one.
- The image targets a root-only, single-purpose "agent workspace"
  container (no multi-user setup, no init system) - Phase 5's
  non-root/sandboxed profile is a separate, later concern.
- Cross-building the Linux image from a macOS host requires a Linux
  builder (standard Nix behavior); this feature does not add remote
  builder configuration.
