---

description: "Task list for PostgreSQL Credential Tooling"

---

# Tasks: PostgreSQL Credential Tooling

**Input**: Design documents from `/specs/013-postgres-credential-tooling/`

## Phase 1: User Story 2 - Declare once, look up by id (P1) 🎯

- [x] T001 [US2] Fetch and read `netspective-labs/sql-aide`'s
      `pgpass.ts`/`pgpass-parse.ts` in full to capture exact descriptor
      format and command semantics
- [x] T002 [US2] Create `pkgs/pgpass/pgpass`: `ls`/`test`/`env`/`url`/
      `psql` subcommands, id/description/boundary comment-header parsing
- [x] T003 [US2] Create `pkgs/pgpass/default.nix`, register in
      `pkgs/default.nix`
- [x] T004 [US2] Verify: `nix build
      .#homeConfigurations.default.activationPackage` succeeds
- [x] T005 [US2] Verify: against a real `~/.pgpass` entry, `pgpass ls`/
      `test`/`env`/`url`/`psql` all produce correct output

**Checkpoint**: connections declared in `~/.pgpass` can be looked up by id

## Phase 2: User Story 1 - Usable `psql` out of the box (P2) 🎯

- [x] T006 [US1] Create `home/postgres.nix`: declarative `~/.psqlrc`
      (ported from the original repo's `dot_psqlrc.tmpl`) + non-clobbering
      `~/.pgpass` stub (mode 600, format documentation only, via
      `pkgs.writeText` + `install -m 600`)
- [x] T007 [US1] Import `./postgres.nix` in `home/default.nix`
- [x] T008 [US1] Verify: real activation creates `~/.psqlrc` and a
      mode-600 `~/.pgpass`; a second activation leaves an edited
      `~/.pgpass` untouched

**Checkpoint**: every profile has a working, pre-configured `psql`

## Phase 3: Polish

- [x] T009 Add `pgpass` and `~/.pgpass`/`~/.psqlrc` checks (including a
      mode-600 check) to `pkgs/doctor/doctor`
- [x] T010 Add the "PostgreSQL credentials" README section: descriptor
      format, every `pgpass` subcommand with runnable examples
- [x] T011 Run `nix flake check --all-systems`, confirm it passes
