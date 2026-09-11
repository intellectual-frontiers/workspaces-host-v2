---

description: "Task list for Agent-Harness Scaffolding"

---

# Tasks: Agent-Harness Scaffolding

**Input**: Design documents from `/specs/003-agent-harness-scaffolding/`

**Tests**: `nix build` per package plus functional smoke tests are this
feature's verification gates.

## Phase 1: User Story 1 - specify and backlog-md packaged (P1) 🎯 MVP

- [x] T001 [P] [US1] Implement `pkgs/specify-cli/default.nix`:
      `buildPythonApplication`, source via `builtins.fetchGit` pinned to a
      known-good commit, `typer`/`json5` bumped via `overridePythonAttrs`,
      `pythonRelaxDeps` for the version floors nixpkgs' click/typer don't
      literally satisfy
- [x] T002 [P] [US1] Implement `pkgs/backlog-md/default.nix`: fetch the
      main npm tarball plus the platform-specific binary package selected
      by `pkgs.stdenv.hostPlatform.system`, wire them together with
      `makeWrapper` over `pkgs.nodejs`
- [x] T003 [US1] Add both to `pkgs/default.nix`'s aggregate (picked up by
      `home/tools.nix` automatically via `builtins.attrValues ported`)

**Checkpoint**: `nix build .#packages.x86_64-linux.{specify-cli,backlog-md}`
both succeed; `./result/bin/specify check` and `./result/bin/backlog --help`
both run correctly

## Phase 2: User Story 2 - scaffold-agent-harness (P1) 🎯 MVP

- [x] T004 [P] [US2] Write `templates/agent-harness/AGENTS.md`,
      `.mcp.json`, `.claude/settings.json`,
      `.claude/hooks/session-start.sh`, `.claude/skills/README.md`
- [x] T005 [US2] Implement `pkgs/scaffold-agent-harness/scaffold-agent-harness`:
      copy every file under `$SCAFFOLD_TEMPLATE_DIR` into the target
      directory, skipping (and reporting) any that already exist
- [x] T006 [US2] Implement `pkgs/scaffold-agent-harness/default.nix`:
      bundle the template directory into `$out/share`, wrap the script
      with `SCAFFOLD_TEMPLATE_DIR` set via `makeWrapper`
- [x] T007 [US2] Add to `pkgs/default.nix`'s aggregate

**Checkpoint**: running `scaffold-agent-harness` against an empty scratch
dir creates all five files; running it again reports all five as skipped

## Phase 3: User Story 3 - Skills directory convention documented (P2)

- [x] T008 [US3] Write `templates/agent-harness/.claude/skills/README.md`
      stating the project-vs-global skills precedence rule (covered by
      T004, listed separately here since it's its own user story)

## Phase 4: Polish

- [x] T009 Run `nix flake check --all-systems`, confirm all three new
      packages evaluate cleanly on all four systems and build on
      x86_64-linux
- [x] T010 Write `specs/003-agent-harness-scaffolding/quickstart.md`
      documenting the verified smoke tests for all three packages
- [x] T011 Update `README.md`'s roadmap table to mark Phase 3 complete

## Dependencies & Execution Order

User Story 1 (specify-cli/backlog-md) and User Story 2
(scaffold-agent-harness) touch entirely disjoint files and were
implemented in parallel. User Story 3 is documentation already produced
alongside User Story 2's template files (T004), listed as its own phase
only for traceability to the spec's own story breakdown.
