---

description: "Task list for Detect the Current Directory Under /mnt, Not Just $HOME"

---

# Tasks: Detect the Current Directory Under /mnt, Not Just $HOME

**Input**: Design documents from `/specs/028-doctor-cwd-mnt-check/`

## Phase 1: User Story 1 - doctor catches a slow-filesystem repo (P1) 🎯

- [x] T001 [US1] Add a `case "$PWD" in /mnt/*)` check to
      `pkgs/doctor/doctor`, alongside the existing `$HOME` check, inside
      the same WSL guard
- [x] T002 [US1] Verify in both states for real: a directory created
      under `/mnt` triggers the warning; a directory on the Linux
      filesystem passes
- [x] T003 [US1] Explain the underlying WSL cross-filesystem
      performance issue and remedy in the WSL walkthrough (a proactive
      callout after the numbered steps) and the `mgit` section (why
      `~/workspaces` matters for speed, not just organization); update
      the Health check summary to mention both `$HOME` and the current
      directory
- [x] T004 [US1] Real build + activation + `doctor` run to confirm the
      new check appears correctly in context
- [x] T005 [US1] Run `nix flake check --all-systems`, confirm it passes
