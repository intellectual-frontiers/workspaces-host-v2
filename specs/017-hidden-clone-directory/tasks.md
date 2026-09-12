---

description: "Task list for Hidden Default Clone Directory"

---

# Tasks: Hidden Default Clone Directory

**Input**: Design documents from `/specs/017-hidden-clone-directory/`

## Phase 1: User Story 1 - Dotted default clone path (P1) 🎯

- [x] T001 [US1] Update `home/shell.nix`'s `WORKSPACES_HOST_REPO` default
      to `${config.home.homeDirectory}/.workspaces-host-v2`
- [x] T002 [US1] Update `pkgs/workspaces-host-update`'s fallback default
      to `$HOME/.workspaces-host-v2`
- [x] T003 [US1] Update every README.md reference to the default clone
      path (clone command, sync section, CLI git-identity example), plus
      a short plain-language note explaining why it's dotted
- [x] T004 [US1] Update `specs/014-sandbox-sync-and-secrets-hygiene/`'s
      `spec.md`/`tasks.md` references to the old default (drift fix,
      excluding the verbatim historical "Input" quote)
- [x] T005 [US1] Verify: `nix build
      .#homeConfigurations.default.activationPackage` succeeds
- [x] T006 [US1] Verify: real activation, checked in an actual fish
      shell, resolves `$WORKSPACES_HOST_REPO` to the dotted path;
      `workspaces-host-update`'s error message (no repo found yet) prints
      the dotted path coherently

**Checkpoint**: a fresh install's clone stays out of a plain `ls ~`

## Phase 2: Polish

- [x] T007 Run `nix flake check --all-systems`, confirm it passes
