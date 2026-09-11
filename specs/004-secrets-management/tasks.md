---

description: "Task list for Secrets Management"

---

# Tasks: Secrets Management

**Input**: Design documents from `/specs/004-secrets-management/`

## Phase 1: User Story 1 - Activation-time secret decryption (P1) 🎯 MVP

- [x] T001 [US1] Implement `home/secrets.nix`: `workspacesHost.secrets`
      option (`sopsFile`, `path` per entry), `home.activation.decryptWorkspacesHostSecrets`
      running `sops --decrypt` into `$XDG_STATE_HOME/workspaces-host/secrets/<path>`
      at mode 600 (dir at 700), guarded by `lib.mkIf (cfg != {})` so it's a
      true no-op when unset
- [x] T002 [US1] Import `secrets.nix` from `home/default.nix`
- [x] T003 [US1] Verify: sops-encrypt a test file with a throwaway age
      key, build a test `homeConfigurations` with `workspacesHost.secrets`
      set, run the resulting activation script, confirm the decrypted
      file's path/mode/content

**Checkpoint**: Secret decrypts correctly at activation time; default
profile (no secrets declared) adds no packages/activation step

## Phase 2: User Story 2 - sensitivectl (P1) 🎯 MVP

- [x] T004 [US2] Implement `pkgs/sensitivectl/sensitivectl`: `list`,
      `backup <profile>`, `restore <profile>` subcommands reading
      `$SENSITIVECTL_CONFIG` (default `~/.config/workspaces-host/sensitivectl.json`),
      shelling out to `rclone sync`, passing through anything after `--`
- [x] T005 [US2] Implement `pkgs/sensitivectl/default.nix`: wrap with
      `rclone`, `jq`, `coreutils` on `PATH`
- [x] T006 [US2] Add to `pkgs/default.nix`'s aggregate
- [x] T007 [US2] Verify: configure a `local`-type rclone remote, back up
      a scratch directory, wipe it, restore, confirm exact round-trip

**Checkpoint**: backup/restore round-trips correctly against a real
(local) rclone remote; unknown profile name fails loudly

## Phase 3: Polish

- [x] T008 Run `nix flake check --all-systems`, confirm `sensitivectl`
      evaluates cleanly on all four systems and builds on x86_64-linux
- [x] T009 Write `specs/004-secrets-management/quickstart.md` with the
      actual verified sops and sensitivectl transcripts
- [x] T010 Update `README.md`'s roadmap table to mark Phase 4 complete

## Dependencies & Execution Order

User Story 1 (`home/secrets.nix`) and User Story 2 (`pkgs/sensitivectl`)
touch entirely disjoint files and were implemented and verified in
parallel.
