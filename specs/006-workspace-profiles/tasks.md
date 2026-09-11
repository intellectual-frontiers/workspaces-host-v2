---

description: "Task list for Workspace Profiles"

---

# Tasks: Workspace Profiles

**Input**: Design documents from `/specs/006-workspace-profiles/`

## Phase 1: User Story 1 - Persona = base + focused extras (P1) 🎯 MVP

- [x] T001 [P] [US1] Write `home/profiles/backend.nix`: `postgresql`,
      `redis`, `docker-compose`, `httpie`
- [x] T002 Refactor `flake.nix`'s `mkHomeConfiguration` to accept an
      `extraModules` list, threading it into `modules` alongside `./home`
- [x] T003 [US1] Verify: activate `.#backend` for real, confirm both
      base tools (`fish`, `semtag`, `specify`, `backlog`) and
      backend-specific tools (`psql`, `redis-cli`, `docker-compose`,
      `http`) resolve on `PATH`

**Checkpoint**: a persona profile demonstrably layers on the base rather
than duplicating or replacing it

## Phase 2: User Story 2 - All four personas ship (P2)

- [x] T004 [P] [US2] Write `home/profiles/data.nix`: `python3`, `uv`,
      `duckdb`
- [x] T005 [P] [US2] Write `home/profiles/mobile.nix`: `android-tools`,
      `watchman`
- [x] T006 [P] [US2] Write `home/profiles/agent-ops.nix`: `gh`, `act`
- [x] T007 [US2] Add `personaModules` + `personaConfigurations` to
      `flake.nix`, exposing `homeConfigurations.{backend,data,mobile,agent-ops}`
- [x] T008 [US2] Verify: `nix build
      .#homeConfigurations.<persona>.activationPackage` succeeds for all
      four names

**Checkpoint**: all four persona configurations build

## Phase 3: Polish

- [x] T009 Run `nix flake check --all-systems`, confirm it still passes
      with the four persona modules added
- [x] T010 Write `specs/006-workspace-profiles/quickstart.md`
- [x] T011 Update `README.md`'s roadmap table to mark Phase 6 complete

## Dependencies & Execution Order

T001/T004/T005/T006 (the four persona module files) are fully parallel -
different files, no dependencies between them. T002 (the
`mkHomeConfiguration` refactor) must land before T007 can wire the
persona configurations through it.
