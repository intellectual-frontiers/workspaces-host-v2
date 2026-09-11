---

description: "Task list for Doctor + Rollback + CI"

---

# Tasks: Doctor + Rollback + CI

**Input**: Design documents from `/specs/007-doctor-rollback-ci/`

## Phase 1: User Story 1 - doctor health check (P1) 🎯 MVP

- [x] T001 [US1] Implement `pkgs/doctor/doctor`: PASS/WARN/FAIL per
      check, all checks always run, non-zero exit iff any FAIL
- [x] T002 [US1] Implement `pkgs/doctor/default.nix`: plain install, no
      `makeWrapper`/fixed PATH (see spec FR-003)
- [x] T003 [US1] Add to `pkgs/default.nix`'s aggregate
- [x] T004 [US1] Verify: run `doctor` against a freshly-activated
      `default` profile (all PASS/WARN, exit 0); run it with an
      artificially broken `PATH` (FAIL present, exit 1)

**Checkpoint**: doctor correctly reports both the healthy and broken case

## Phase 2: User Story 2 - Rollback verified and documented (P2)

- [x] T005 [US2] Verify: activate generation 1 (base profile), build and
      activate generation 2 with an added marker file, confirm the
      marker is present; re-activate generation 1's own store path via
      `home-manager generations`, confirm the marker is gone
- [x] T006 [US2] Document the rollback mechanism (README + this
      feature's `quickstart.md`) with the actual verified transcript

**Checkpoint**: a real rollback cycle demonstrably restores prior state

## Phase 3: User Story 3 - CI (P1)

- [x] T007 [US3] Write `.github/workflows/ci.yml`: checkout,
      `cachix/install-nix-action`, `nix flake check --all-systems`,
      explicit builds of `oci-image` and `oci-image-sandboxed`, a
      `doctor` run against a real `homeConfigurations.default` activation
- [x] T008 [US3] Verify: open this feature's own pull request and confirm
      the workflow runs and all its steps pass on GitHub Actions

**Checkpoint**: CI is live and green on this feature's own PR

## Phase 4: Polish

- [x] T009 Run `nix flake check --all-systems` locally, confirm `doctor`
      evaluates and builds cleanly on all four systems
- [x] T010 Write `specs/007-doctor-rollback-ci/quickstart.md`
- [x] T011 Update `README.md`'s roadmap table to mark Phase 7 complete,
      and add the rollback documentation

## Dependencies & Execution Order

The three user stories are independent (different files: `pkgs/doctor/`,
a verification exercise with no new files, `.github/workflows/ci.yml`)
and were implemented in that order only because CI's last step exercises
`doctor`, so `doctor` needed to exist first.
