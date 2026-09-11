---

description: "Task list for Core Flake + Home-Manager Module"

---

# Tasks: Core Flake + Home-Manager Module

**Input**: Design documents from `/specs/001-core-flake-home-manager/`

**Prerequisites**: plan.md, spec.md

**Tests**: No unit-test framework applies to a Nix/dotfiles flake; `nix flake check`
and the quickstart's manual `home-manager switch` smoke test are this feature's
verification gates in place of unit tests.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1/US2/US3)

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 Create `flake.nix` with `inputs` for `nixpkgs`, `home-manager`,
      and `flake-utils`, and an empty `outputs` function wired through
      `flake-utils.lib.eachDefaultSystem`
- [ ] T002 Run `nix flake lock` to generate `flake.lock` pinning all three inputs
- [ ] T003 [P] Create `home/`, `pkgs/`, and `themes/oh-my-posh/` directories per plan.md's structure

**Checkpoint**: `nix flake metadata` resolves the flake with no errors

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The home-manager scaffolding every user story's module plugs into

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Add `home-manager` as a proper flake input (`inputs.home-manager.url`,
      `inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs"`) in `flake.nix`
- [ ] T005 Create `home/default.nix` as the top-level home-manager module stub
      (declares `home.stateVersion`, `home.username`, `home.homeDirectory`,
      and `imports = [ ./shell.nix ./direnv.nix ./git.nix ]`)
- [ ] T006 Wire `homeConfigurations.default` in `flake.nix`, using
      `home-manager.lib.homeManagerConfiguration` with `modules = [ ./home/default.nix ]`,
      for each system in `eachDefaultSystem`
- [ ] T007 Add a `checks.<system>.default` output in `flake.nix` that builds
      `homeConfigurations.default.activationPackage`, so `nix flake check`
      exercises the whole module

**Checkpoint**: `home-manager build --flake .#default` produces a store path with no errors (module files are still stubs)

---

## Phase 3: User Story 1 - Reproducible shell environment (Priority: P1) 🎯 MVP

**Goal**: Fish + oh-my-posh + direnv/nix-direnv work end-to-end from a clean `home-manager switch`

**Independent Test**: On a clean checkout, `home-manager switch --flake .#default` completes, opens Fish with a themed prompt, and `direnv status` reports nix-direnv active

### Implementation for User Story 1

- [ ] T008 [P] [US1] Create `themes/oh-my-posh/default.omp.json` with a documented default theme
- [ ] T009 [P] [US1] Implement `home/shell.nix`: `programs.fish.enable = true`,
      set as the module's shell, `programs.oh-my-posh.enable = true` pointed at
      `themes/oh-my-posh/default.omp.json`, Fish init hook to source oh-my-posh
- [ ] T010 [US1] Implement `home/direnv.nix`: `programs.direnv.enable = true`,
      `programs.direnv.nix-direnv.enable = true`, `programs.direnv.enableFishIntegration = true`
- [ ] T011 [US1] Import `shell.nix` and `direnv.nix` from `home/default.nix` (if not already wired in T005)
- [ ] T012 [US1] Write `specs/001-core-flake-home-manager/quickstart.md` documenting the
      `home-manager switch --flake .#default` smoke test steps and expected observations
      (Fish prompt visible, `direnv status` output) for manual verification

**Checkpoint**: User Story 1's independent test passes via manual smoke test per quickstart.md

---

## Phase 4: User Story 2 - Declarative git identity (Priority: P2)

**Goal**: `~/.gitconfig` is generated from home-manager options, not hand-edited or templated by chezmoi

**Independent Test**: Set identity options in the flake config, apply, confirm `git config --get user.name`/`user.email` and default aliases/settings resolve correctly

### Implementation for User Story 2

- [ ] T013 [US2] Implement `home/git.nix`: expose `programs.git.enable`,
      `programs.git.userName`, `programs.git.userEmail` (surfaced as this
      profile's declarative identity options), plus `programs.git.aliases`
      and safe defaults (`init.defaultBranch = "main"`, `pull.rebase = true`,
      etc.)
- [ ] T014 [US2] Import `git.nix` from `home/default.nix` and set placeholder/
      example identity values in `flake.nix`'s `homeConfigurations.default`
      module arguments (documented as "override per-user" in quickstart.md)
- [ ] T015 [US2] Extend `specs/001-core-flake-home-manager/quickstart.md` with
      the git-identity verification steps (`git config --get user.name`, etc.)

**Checkpoint**: User Stories 1 and 2 both pass their independent tests

---

## Phase 5: User Story 3 - Ported git helper scripts (Priority: P3)

**Goal**: `semtag`, `mgitstatus`, `git-standup` are flake-packaged and on `PATH` after activation

**Independent Test**: `which semtag mgitstatus git-standup` all resolve under the Nix store after `home-manager switch`

### Implementation for User Story 3

- [ ] T016 [P] [US3] Write `pkgs/semtag/semtag` (POSIX sh) and
      `pkgs/semtag/default.nix` (a `writeShellApplication`/`stdenv.mkDerivation`
      packaging it)
- [ ] T017 [P] [US3] Write `pkgs/mgitstatus/mgitstatus` and `pkgs/mgitstatus/default.nix`
- [ ] T018 [P] [US3] Write `pkgs/git-standup/git-standup` and `pkgs/git-standup/default.nix`
- [ ] T019 [US3] Create `pkgs/default.nix` aggregating the three derivations,
      keyed by name, for reuse from both `packages.<system>` and `home.packages`
- [ ] T020 [US3] Expose the three packages via `packages.<system>` in `flake.nix`
      (depends on T016-T019)
- [ ] T021 [US3] Add the three packages to `home.packages` in `home/default.nix`
      (or a new `home/tools.nix` imported from it) so they land on `PATH` after activation
- [ ] T022 [US3] Extend `quickstart.md` with the `which semtag mgitstatus git-standup`
      verification step

**Checkpoint**: All three user stories pass their independent tests

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T023 [P] Add a top-level `## Quickstart` link from `README.md` to
      `specs/001-core-flake-home-manager/quickstart.md`
- [ ] T024 Run `nix flake check` and resolve any evaluation/build errors across all modules and packages
- [ ] T025 Run the full `quickstart.md` smoke test end-to-end on a scratch `$HOME` and record the result in the PR description

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational only
- **User Story 2 (Phase 4)**: Depends on Foundational only (independent of US1's files)
- **User Story 3 (Phase 5)**: Depends on Foundational only (independent of US1/US2's files)
- **Polish (Phase 6)**: Depends on all three user stories being complete

### Parallel Opportunities

- T008/T009 (US1) can run in parallel with each other; T010 depends on T009 landing in `home/default.nix`'s import list only loosely (different files, so effectively parallel)
- US1, US2, US3 touch disjoint files (`shell.nix`+`direnv.nix` vs. `git.nix` vs. `pkgs/*`) and can be implemented in parallel once Phase 2 is done
- T016, T017, T018 (the three ported scripts) are fully parallel — different directories

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (Setup) and Phase 2 (Foundational)
2. Complete Phase 3 (User Story 1)
3. **STOP and VALIDATE**: run the quickstart smoke test for US1 alone
4. This is the demonstrable MVP: a reproducible Fish+oh-my-posh+direnv shell

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. User Story 1 → validate → MVP demonstrable
3. User Story 2 → validate → git identity declarative
4. User Story 3 → validate → helper scripts on PATH
5. Polish → `nix flake check` green, quickstart fully documented
