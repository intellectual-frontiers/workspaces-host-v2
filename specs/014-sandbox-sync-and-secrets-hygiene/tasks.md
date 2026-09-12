---

description: "Task list for Sandbox Sync & Secrets Hygiene"

---

# Tasks: Sandbox Sync & Secrets Hygiene

**Input**: Design documents from `/specs/014-sandbox-sync-and-secrets-hygiene/`

## Phase 1: User Story 1 - Notice and apply upstream updates (P1) 🎯

- [x] T001 [US1] Create `pkgs/workspaces-host-update/workspaces-host-update`:
      `git -C $WORKSPACES_HOST_REPO pull --ff-only` then
      `home-manager switch --flake $WORKSPACES_HOST_REPO#$WORKSPACES_HOST_PROFILE`,
      with a clear error if the repo path isn't a git clone
- [x] T002 [US1] Create `pkgs/workspaces-host-update/default.nix`, register
      in `pkgs/default.nix`
- [x] T003 [US1] Add `home.sessionVariables.WORKSPACES_HOST_REPO` (default
      `~/.workspaces-host-v2`) to `home/shell.nix`
- [x] T004 [US1] Add the once-a-day backgrounded nudge to `home/shell.nix`'s
      `interactiveShellInit` (stamp file under `$XDG_STATE_HOME/workspaces-host/`,
      background `git fetch` + `rev-list --count`, silent on any failure)
- [x] T005 [US1] Verify: `nix build
      .#homeConfigurations.default.activationPackage` succeeds; `fish -n`
      against the generated `config.fish` passes
- [x] T006 [US1] Verify for real (not just syntax-checked): a local bare
      "origin" one commit ahead of a clone at the default
      `~/.workspaces-host-v2` path triggers the nudge in a real interactive
      fish shell exactly once, is silent on a same-day second shell, and
      `workspaces-host-update` correctly fast-forwards the clone
- [x] T007 [US1] Add `$WORKSPACES_HOST_REPO` check to `pkgs/doctor/doctor`

**Checkpoint**: an engineer is passively notified when upstream moves and
has a one-command way to catch up

## Phase 2: User Story 2 - Short-lived tokens via env (P1) 🎯

- [x] T008 [US2] Add `gitleaks` to `home/tools.nix`
- [x] T009 [US2] Write README's "Secrets & credential hygiene" section:
      `.gitignore`/staged-diff-review/`gitleaks detect` habits, the
      concrete sops/age-encrypt → `workspacesHost.secrets` →
      direnv-`.envrc`-export walkthrough for a short-lived GitHub/GitLab
      token, and the rotation flow (re-encrypt, re-activate, no code
      change)

**Checkpoint**: README gives a concrete, copy-pasteable path to "never put
a real token in a config file"

## Phase 3: Polish

- [x] T010 Update README's clone step to standardize on
      `~/.workspaces-host-v2` (matching `WORKSPACES_HOST_REPO`'s default),
      noting the override for engineers already cloned elsewhere
- [x] T011 Write README's "Keeping your sandbox in sync" section: manual
      steps, `workspaces-host-update`, the nudge's behavior/guarantees
- [x] T012 Run `nix flake check --all-systems`, confirm it passes
