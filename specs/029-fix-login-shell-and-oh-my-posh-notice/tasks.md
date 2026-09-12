---

description: "Task list for Fix Login Shell Not Switching to fish, and the oh-my-posh Upgrade Nag"

---

# Tasks: Fix Login Shell Not Switching to fish, and the oh-my-posh Upgrade Nag

**Input**: Design documents from `/specs/029-fix-login-shell-and-oh-my-posh-notice/`

## Phase 1: User Story 1 - A fresh install actually starts in fish (P1) 🎯

- [x] T001 [US1] Add a best-effort `chsh` step to `install.sh`, after
      activation: register `$HOME/.nix-profile/bin/fish` in
      `/etc/shells` if needed, then `chsh` to it, warning (not
      aborting) on failure at either step
- [x] T002 [US1] Verify for real against this sandbox's own root
      account: bash to fish, idempotent re-run (no-op when already
      fish), restored to bash afterward to avoid a lingering side effect

**Checkpoint**: a fresh install's next new terminal window actually
starts in fish, with no manual `chsh` needed

## Phase 2: User Story 2 - doctor reports the real login shell (P1) 🎯

- [x] T003 [US2] Add a login-shell check to `pkgs/doctor/doctor`
      (`getent passwd`, not `$SHELL`, which only reflects whatever
      shell is currently running), independent of the existing "fish is
      on PATH" check
- [x] T004 [US2] Verify both states for real: bash (warns with the
      exact fix command) and fish (passes)

**Checkpoint**: this is never a silent gap again, even on a machine
where the automatic `chsh` failed

## Phase 3: User Story 3 - Silence the oh-my-posh nag without fighting Nix (P1) 🎯

- [x] T005 [US3] Merge `disable_notice = true;` into
      `programs.oh-my-posh.settings` in `home/shell.nix`, keeping the
      checked-in theme file untouched; document why `enable
      autoupgrade` was rejected (read-only Nix store) directly in the
      comment
- [x] T006 [US3] Real build + activation: confirm `disable_notice: true`
      in the generated config and zero diff on the checked-in theme
      file

**Checkpoint**: the upgrade nag is gone without introducing a
self-modifying binary into a Nix-managed profile

## Phase 4: Polish

- [x] T007 Update README: the WSL walkthrough's close-and-reopen note
      and automatic-`chsh`-with-fallback explanation; a new "Using VS
      Code with this setup (WSL)" section (documentation only - nothing
      in this repo manages VS Code); the Health check doctor-coverage
      summary
- [x] T008 Run `sh -n`/`dash -n` on `install.sh` and
      `pkgs/doctor/doctor`
- [x] T009 Run `nix flake check --all-systems`, confirm it passes
