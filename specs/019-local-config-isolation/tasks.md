---

description: "Task list for Local Configuration Isolation & Real-Identity Profiles"

---

# Tasks: Local Configuration Isolation & Real-Identity Profiles

**Input**: Design documents from `/specs/019-local-config-isolation/`

## Phase 1: User Story 1 - Activation works with your actual username (P1) 🎯

- [x] T001 [US1] Confirm `home-manager switch`/`nix build` support
      `--impure` (checked `home-manager --help` directly, not assumed)
- [x] T002 [US1] Add `mkCurrentUserHomeConfiguration` to `flake.nix`
      (`builtins.getEnv "USER"`/`"HOME"`, `builtins.currentSystem`)
- [x] T003 [US1] Add `homeConfigurations.current` and
      `homeConfigurations."current-<persona>"` (one per `personaModules`
      entry), leaving every existing attribute unchanged
- [x] T004 [US1] Verify: `nix build
      .#homeConfigurations.current.activationPackage --impure` succeeds
      and `./result/activate` succeeds as the real, non-"workspace" user
      running it (this project's own dev sandbox) - caught and fixed a
      real bug here: `$USER` unset even though `whoami` works
- [x] T005 [US1] Verify: `nix flake check --all-systems` (no `--impure`)
      still passes, completely unchanged

**Checkpoint**: real installs work with whoever's actually running them,
CI stays fully pure and unaffected

## Phase 2: User Story 2 - Personal overrides never touch a repo file (P1) 🎯

- [x] T006 [US2] Add local.nix import to `home/default.nix`
      (`~/.config/workspaces-host/local.nix`, conditional on
      `builtins.pathExists`) - caught and fixed a real infinite-recursion
      bug here (`pkgs.lib.optional` inside the same module's own
      `imports` computation; fixed with a plain `if/then/else` instead)
      and a path-vs-string bug (`/. + string` coercion needed)
- [x] T007 [US2] Change `home/git.nix`'s `userName`/`userEmail` to
      `lib.mkDefault`
- [x] T008 [US2] Create tracked `local.nix.example` at the repo root
- [x] T009 [US2] Verify: a real `local.nix` with a git identity override,
      built and activated with `--impure`, produces the expected
      `~/.config/git/config` content (inspected the actual generated
      file directly, since this sandbox's own pre-existing
      `~/.gitconfig`/repo-local `.git/config` mask `git config --get`
      itself - a sandbox-specific artifact, not a bug, confirmed by
      temporarily moving them aside)
- [x] T010 [US2] Verify: `nix flake check` is unaffected by `local.nix`'s
      presence or absence

**Checkpoint**: git identity (and, generally, personal secrets
declarations) live entirely outside the repo, immune to every future
`git pull`

## Phase 3: Polish

- [x] T011 Update `pkgs/workspaces-host-update`: default
      `WORKSPACES_HOST_PROFILE` to `current`, add `--impure`, defensive
      `whoami` fallback for `$USER`
- [x] T012 Add `local.nix` existence check and placeholder-vs-unset git
      email distinction to `pkgs/doctor/doctor`; verify both branches for
      real
- [x] T013 Update README: WSL walkthrough uses `current --impure`,
      macOS section simplified (no more per-arch attribute selection),
      sync section's `WORKSPACES_HOST_PROFILE` default, git-identity
      instructions rewritten around `local.nix`, secrets-declaration
      instructions updated to reference `local.nix`'s location, Java
      toolchain's stale "same pattern as git identity" comparison removed
- [x] T014 Run `nix flake check --all-systems`, confirm it passes
