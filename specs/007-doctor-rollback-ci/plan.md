# Implementation Plan: Doctor + Rollback + CI

**Branch**: `007-doctor-rollback-ci` | **Date**: 2026-09-11 | **Spec**: [spec.md](./spec.md)

## Summary

Add `pkgs/doctor` (an unwrapped POSIX `sh` health check), document and
verify home-manager's built-in generation rollback (no new tooling), and
add `.github/workflows/ci.yml` running `nix flake check` plus explicit
builds of both OCI images and a `doctor` run against a real activation.

## Technical Context

**Language/Version**: POSIX `sh` (`doctor`), YAML (GitHub Actions).

**Primary Dependencies**: None new - `doctor` only shells out to
`command -v`/`nix show-config`/`git config`, all either POSIX or already
present wherever this flake's tools are.

**Storage**: N/A.

**Testing**: `doctor` run against a real freshly-activated profile
(all-PASS case) and against an artificially broken `PATH` (FAIL case,
verifying the non-zero exit); a real two-generation activate/rollback
cycle using a throwaway marker file; the CI workflow itself run against
this feature's own pull request (a real GitHub Actions run, not just
YAML lint).

**Target Platform**: `doctor` and the CI workflow are cross-platform
(the workflow runs on `ubuntu-latest`, matching this repo's primary
target; `doctor`'s checks are all POSIX-portable).

**Project Type**: Additions to the existing single Nix project, plus a
`.github/workflows/` directory (new to this repo, first CI in it).

**Constraints**: `doctor` must not be wrapped with a fixed `PATH` (spec
FR-003) - the one deliberate exception to this repo's usual `pkgs/*`
wrapping pattern, and called out explicitly in its own `default.nix` so
it doesn't look like an oversight.

**Scale/Scope**: One health-check command, one CI workflow, and
documentation of an existing mechanism (rollback) rather than new code
for it.

## Constitution Check

- **Principle I**: `doctor` and the CI workflow add no new flake inputs;
  CI runs against the exact same `flake.lock` an engineer would use
  locally.
- **Principle II**: Rollback IS this principle's own payoff, made
  concrete and documented - "destroy and rebuild" extends naturally to
  "or reactivate an earlier build," which Nix gives for free.
- **Principle III**: N/A.
- **Principle IV**: CI explicitly builds both OCI images on every PR,
  turning Principle IV's "container/host parity" claim into something
  continuously checked, not just asserted once in this session.
- **Principle V**: Single feature, single PR - the three legs (doctor,
  rollback docs, CI) are small enough and interdependent enough (CI's
  own last step runs `doctor`) to ship together rather than as three
  separate phases.

No violations.

## Project Structure

```text
pkgs/doctor/
├── default.nix       # unwrapped install (no makeWrapper) - see spec FR-003
└── doctor

.github/workflows/
└── ci.yml

specs/007-doctor-rollback-ci/
├── plan.md
├── quickstart.md      # includes the verified rollback transcript
└── tasks.md
```

**Structure Decision**: `pkgs/doctor/` follows the existing `pkgs/<name>/`
layout; `.github/workflows/` is new to this repo (its first CI), placed
at the conventional GitHub Actions path.

## Complexity Tracking

*No constitution violations - table not needed.*
