# Feature Specification: Bulk Multi-Repo Git Tooling

**Feature Branch**: `012-bulk-git-tooling`

**Created**: 2026-09-12

**Status**: Draft

**Input**: Gap analysis comparing `workspaces-host-v2` against
`strategy-coach/workspaces-host` found that the original README
documented `git-extras` (baseline, always installed) and `git-xargs`
(opt-in on request) for making changes across many repos at once -
neither exists in `workspaces-host-v2` today, even though this rewrite
now has its own native multi-repo management (`pkgs/mgit`,
`home/workspaces.nix`, Phase 10) that these tools directly complement.

## Background

The original repo's README named two tools for this purpose:
`git-extras` - described as baseline tooling, always installed - and
[`git-xargs`](https://github.com/gruntwork-io/git-xargs), which the
README explicitly said was "not installed by default but... let us know
and we'll have it installed as a standard package." This rewrite
consolidates that kind of case-by-case optional tooling into standard,
always-installed packages rather than tracking an ad hoc allowlist, so
`git-xargs` is installed by default here.

Neither tool duplicates `mgit`: `mgit` governs *which* repos exist under
`~/workspaces` (clone-or-pull by a governed directory layout); these two
tools operate *across* whatever repos are already there (or across an
arbitrary GitHub selection, for `git-xargs`) to make the same change to
many of them at once.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Everyday git subcommands (`git-extras`) (Priority: P1)

An engineer gets a large set of extra `git <cmd>` subcommands
(`git summary`, `git changelog`, `git effort`,
`git delete-merged-branches`, ...) on every profile without installing
anything extra, matching the original repo's baseline tooling.

**Why this priority**: The original README's own "baseline, always
installed" tool - the simpler, unconditional half of this feature.

**Independent Test**: After activation, run `git extras --version` (or
plain `git-extras --version`) inside any git repo; it prints a version
and exits 0.

**Acceptance Scenarios**:

1. **Given** a fresh activation on any of this flake's four supported
   systems, **When** `git extras --version` runs, **Then** it prints a
   version and exits 0.
2. **Given** `git-extras` is installed, **When** an engineer runs any of
   its subcommands (e.g. `git summary`) inside a git repo, **Then** it
   behaves as documented upstream - this repo only guarantees the binary
   is on `PATH`, not its own copy of upstream's behavior.

---

### User Story 2 - Bulk changes across many repos (`git-xargs`) (Priority: P1)

An engineer with several repos under `~/workspaces` (via `mgit`) runs one
`git-xargs` invocation to apply the same script/command to all of them
and open a PR with the results in each, without installing anything
extra - unlike the original repo, where this required an explicit
request to get it added.

**Why this priority**: The actual capability gap this feature restores -
`git-extras` alone doesn't cover "apply this change to N repos and open
N PRs."

**Independent Test**: After activation, run `git-xargs --help`; it
prints usage and exits 0.

**Acceptance Scenarios**:

1. **Given** a fresh activation on any of this flake's four supported
   systems, **When** `git-xargs --help` runs, **Then** it prints usage
   and exits 0.
2. **Given** `git-xargs` is on `PATH`, **When** nothing further is done,
   **Then** it makes no GitHub API calls on its own - it's a CLI an
   engineer invokes explicitly with their own repo selection and
   GitHub token, not a background process this repository starts.

### Edge Cases

- `git-xargs` is not packaged in nixpkgs - it's fetched as a prebuilt
  binary from its GitHub releases (`gruntwork-io/git-xargs`), the same
  category of port `pkgs/backlog-md` already established, following its
  per-system asset-map pattern.
- Unlike `surveilr` (compliance/observability tooling, a separate
  feature), `git-xargs` genuinely publishes a release binary for all
  four of this flake's supported systems, so no conditional
  per-system exclusion is needed here.
- nixpkgs' `git-extras` bundles its own `bin/git-standup`, which
  collides with this repo's own, already-ported `pkgs/git-standup` (a
  different, native implementation, from an earlier feature) - a hard
  `home-manager-path` build failure, not a warning. Resolved by wrapping
  `git-extras` in `pkgs.lib.lowPrio` so this repo's own `git-standup`
  wins the collision, leaving every other `git-extras` subcommand
  unaffected.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `home/tools.nix` MUST add nixpkgs' `git-extras` (a plain,
  platform-unrestricted package) to its existing `home.packages` list,
  installed on every profile across all four supported systems.
- **FR-002**: A new `pkgs/git-xargs` package MUST fetch the `git-xargs`
  binary for the current system from its GitHub releases
  (`gruntwork-io/git-xargs`) via `fetchurl`, install it at
  `$out/bin/git-xargs`, and be registered in `pkgs/default.nix`'s
  aggregate unconditionally (a real asset exists for all four supported
  systems).
- **FR-003**: `pkgs/doctor/doctor` MUST report `git-extras` and
  `git-xargs` on `PATH` in its existing ported-tools check loop.
- **FR-004**: README.md MUST document what each tool is for and that
  they're installed on `PATH` by every profile, placed alongside the
  existing `mgit`/workspace-management documentation since the tools
  directly complement it, matching this repo's terse, factual
  documentation voice.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix build .#homeConfigurations.default.activationPackage`
  succeeds with both tools included.
- **SC-002**: A real activation puts `git-extras` and `git-xargs` on
  `PATH`; `git extras --version` and `git-xargs --help` each exit 0.
- **SC-003**: `doctor` reports both tools accurately.
- **SC-004**: `nix flake check --all-systems` continues to pass.

## Assumptions

- `git-extras`'s nixpkgs package (`pkgs/by-name/gi/git-extras`) declares
  `meta.platforms = platforms.all` - verified directly against this
  flake's exact pinned `nixpkgs` commit (`nixos-24.11`, rev
  `50ab793786d9de88ee30ec4e4c24fb4236fc2674`) - so it's added
  unconditionally, the same as `ripgrep`/`fd`/etc. in the same list.
- `git-xargs`'s real GitHub releases (`gruntwork-io/git-xargs`, tag
  `v0.1.16` at the time of this feature) were inspected directly: it
  publishes `git-xargs_linux_amd64`, `git-xargs_linux_arm64`,
  `git-xargs_darwin_amd64`, and `git-xargs_darwin_arm64` (plus two
  Windows `.exe`s and a `SHA256SUMS`, not relevant here) - one asset per
  system this flake supports, each a plain unarchived static binary
  (`dontUnpack = true`, direct `install -Dm755`), unlike `surveilr`'s
  archived assets.
