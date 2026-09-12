---

description: "Task list for One-Step Installer"

---

# Tasks: One-Step Installer

**Input**: Design documents from `/specs/020-one-step-installer/`

## Phase 1: User Story 1 - One command from fresh machine to working sandbox (P1) 🎯

- [x] T001 [US1] Write `install.sh`: distro-family detection
      (`/etc/os-release` `ID`/`ID_LIKE`) for `apt`/`dnf`/`pacman`,
      macOS handling, clear failure for anything unrecognized
- [x] T002 [US1] Add idempotent Nix install (single-user, skip if
      already present), flakes-enablement, and clone-or-update steps
- [x] T003 [US1] Add build+activate step
      (`homeConfigurations.$WORKSPACES_HOST_PROFILE`, default `current`,
      `--impure`)
- [x] T004 [US1] Verify: `sh -n install.sh` and `dash -n install.sh` both
      pass - caught and fixed a real bug here (bash-only `<(...)` process
      substitution isn't valid POSIX `sh`)
- [x] T005 [US1] Verify for real: run against a fresh
      `$WORKSPACES_HOST_REPO` test path in this project's own dev
      sandbox - clones, builds, and activates `current` successfully
- [x] T006 [US1] Verify: re-run immediately after - reports "updating
      existing clone" instead of re-cloning, `nix.conf` has no duplicate
      flakes line, activation reuses the existing generation (no change)
- [x] T007 [US1] Verify: run against a path that exists but isn't a git
      clone - exits non-zero with a clear message, path untouched

**Checkpoint**: a fresh WSL/VM/server reaches a working, verified sandbox
via one copy-pasted command

## Phase 2: Polish

- [x] T008 Rewrite README's Windows/WSL walkthrough: `install.sh` as the
      lead step (steps 4-7 collapsed into one), manual-equivalent
      commands preserved in a new "What the installer actually does"
      section, using `sh -c "$(curl -fsSL ...)"` rather than
      `curl ... | sh` (documented why: preserves real terminal stdin for
      any downstream interactive prompt)
- [x] T009 Simplify README's "Other platforms" section now that
      `install.sh` absorbs per-distro/per-arch handling; fix the
      WSL-Docker/systemd callout, which no longer points at a
      "systemd-enabled install" variant that no longer exists
- [x] T010 Fix the stray "Step 7" cross-reference in "Fonts for the
      prompt icons" (now "Step 4")
- [x] T011 Run `nix flake check --all-systems`, confirm it passes
