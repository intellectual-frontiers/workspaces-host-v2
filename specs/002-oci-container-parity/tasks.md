---

description: "Task list for Container/OCI Parity"

---

# Tasks: Container/OCI Parity

**Input**: Design documents from `/specs/002-oci-container-parity/`

**Tests**: `nix build` of the image derivation plus a manual `docker load`/`run`
smoke test are this feature's verification gates.

## Phase 1: Setup

- [x] T001 Create `oci/default.nix` taking `{ pkgs, homeConfig }`

## Phase 2: Foundational

- [x] T002 Refactor `flake.nix`'s `outputs` `let` block to compute
      `homeConfigurationsFor = forAllSystems mkHomeConfiguration` once, so
      `packages`, `homeConfigurations`, and `checks` all reference it
      (no duplicate evaluation)

## Phase 3: User Story 1 - One command produces a runnable container (P1) 🎯 MVP

- [x] T003 [US1] Implement `oci/default.nix`: `dockerTools.buildLayeredImage`
      with `contents = homeConfig.config.home.packages ++ [ bashInteractive
      coreutils cacert dockerTools.fakeNss ]`
- [x] T004 [US1] Copy the generated dotfiles (`fish/config.fish`,
      `git/config`, `oh-my-posh/config.json`,
      `direnv/lib/hm-nix-direnv.sh`) from `homeConfig.config.xdg.configFile.*.source`
      into `/root/.config/...` via `extraCommands`
- [x] T005 [US1] Wire `packages.<system>.oci-image = import ./oci { inherit
      pkgs; homeConfig = homeConfigurationsFor.${system}; }` in `flake.nix`
- [x] T006 [US1] Write `specs/002-oci-container-parity/quickstart.md`
      documenting the `nix build` + `docker load` + `docker run` smoke test
      and its expected output

**Checkpoint**: `nix build .#packages.x86_64-linux.oci-image` succeeds;
`docker load` + `docker run ... fish -c 'fish --version'` etc. all pass

## Phase 4: User Story 2 - Builds without a container runtime (P2)

- [x] T007 [US2] Confirm (and note in quickstart.md) that `nix build` of
      the image derivation has no dependency on `docker`/`podman` being
      installed or running - only loading/running the tarball does

## Phase 5: Polish

- [x] T008 Run `nix flake check --all-systems` and confirm the new
      `oci-image` package output evaluates cleanly on all four systems
- [x] T009 Update `README.md`'s roadmap table to mark Phase 2 complete

## Dependencies & Execution Order

Setup → Foundational → User Story 1 (MVP) → User Story 2 → Polish. User
Story 2 is a documentation/verification-only addition on top of User
Story 1's implementation (no new code).
