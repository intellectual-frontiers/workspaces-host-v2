---

description: "Task list for Workspace Repo Management (mgit)"

---

# Tasks: Workspace Repo Management (mgit)

**Input**: Design documents from `/specs/010-workspace-repo-management/`

## Phase 1: User Story 1 - Clone-or-pull by governed layout (P1) 🎯

- [x] T001 [US1] Read `strategy-coach/workspaces`'s `mgit.ts`/`ws-ensure.ts`/
      `doctor.ts`/`README.md` in full to capture exact semantics to port
- [x] T002 [US1] Create `pkgs/mgit/mgit`: `ensure` subcommand - JSON config
      at `$MGIT_CONFIG`, clone-or-pull to
      `$WORKSPACES_HOME/<repo-path>`, `"fresh": true` force-re-clone,
      per-repo failure isolation (one bad entry doesn't abort the batch)
- [x] T003 [US1] Create `pkgs/mgit/default.nix`, register in
      `pkgs/default.nix`
- [x] T004 [US1] Create `home/workspaces.nix` (bootstrap `~/workspaces` +
      empty `mgit.json` via `home.activation`, non-clobbering), import in
      `home/default.nix`
- [x] T005 [US1] Verify: `nix build
      .#homeConfigurations.default.activationPackage` succeeds
- [x] T006 [US1] Verify: real activation creates `~/workspaces/mgit.json`;
      a second activation leaves an edited `mgit.json` untouched
- [x] T007 [US1] Verify: `mgit ensure` against a real public repo clones
      it to `~/workspaces/<host>/<org>/<repo>`; a second run pulls instead

**Checkpoint**: repos declared in `mgit.json` can be idempotently
cloned/pulled into a governed layout

## Phase 2: User Story 2 - VS Code monorepo composition (P2) 🎯

- [x] T008 [US2] Implement `resolve_workspace_deps` in `pkgs/mgit/mgit`:
      find `*.mgit.code-workspace` files in a repo, symlink to
      `$WORKSPACES_HOME`, parse `folders[].path`, recursively `ensure_repo`
      each - deduplicated via a per-run "handled" set to prevent
      self-/mutually-referencing cycles from looping forever
- [x] T009 [US2] Verify: a synthetic `*.mgit.code-workspace` fixture (with
      a self-reference and an intentionally-invalid dependent repo path)
      is symlinked correctly, its dependent repos are resolved recursively
      exactly once each, and the invalid entry fails gracefully without
      aborting or looping

**Checkpoint**: dependent repos referenced by a workspace file's `folders`
are cloned automatically

## Phase 3: User Story 3 - Status and inspection (P2) 🎯

- [x] T010 [US3] Implement `status` subcommand (delegates to `mgitstatus`)
      and `inspect` subcommand (git-hosts + repo list from
      `*.mgit.code-workspace` files) in `pkgs/mgit/mgit`
- [x] T011 [US3] Verify: `mgit status` and `mgit inspect` produce accurate
      output against the real/synthetic fixtures from T007/T009

**Checkpoint**: an engineer can audit the whole workspace without `cd`-ing
into each repo

## Phase 4: Polish

- [x] T012 Add `mgit` and `~/workspaces`/`mgit.json` checks to
      `pkgs/doctor/doctor`
- [x] T013 Update README.md roadmap table (phases 8-10 were missing -
      drift from prior features not updating it) and add the "Managing
      your `~/workspaces` repos (mgit)" section: directory convention,
      `mgit.json` format, subcommands, VS Code composition example
- [x] T014 Run `nix flake check --all-systems`, confirm it passes
