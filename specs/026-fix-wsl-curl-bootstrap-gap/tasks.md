---

description: "Task list for Fix the curl Bootstrap Gap on Fresh WSL Debian"

---

# Tasks: Fix the curl Bootstrap Gap on Fresh WSL Debian

**Input**: Design documents from `/specs/026-fix-wsl-curl-bootstrap-gap/`

## Phase 1: User Story 1 - The documented first command actually works (P1) 🎯

- [x] T001 [US1] Prefix the Windows/WSL walkthrough's step-4 command with
      `sudo apt-get update && sudo apt-get install -y curl git &&`,
      and rewrite the surrounding prose to explain why (a fresh minimal
      Debian image has neither tool yet) instead of claiming the
      installer alone handles it
- [x] T002 [US1] Fix "Other platforms" to stop claiming the identical
      command works unchanged everywhere: Linux families get a
      check-first/install-with-your-package-manager note (`apt-get`/
      `dnf`/`pacman`), macOS gets an explicit "always already there, no
      prefix" note
- [x] T003 [US1] Verify the new command is syntax-valid under `sh -n`
      and `dash -n`; confirm no stale copy of the old unprefixed
      one-liner remains anywhere in the README
- [x] T004 [US1] Confirm "What the installer actually does" (manual
      steps) needed no change - it already listed `apt install curl
      git` as its own first line

**Checkpoint**: the exact command a brand-new Windows/WSL user is told
to run actually succeeds on a genuinely fresh Debian image
