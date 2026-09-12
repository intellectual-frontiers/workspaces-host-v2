---

description: "Task list for README Outcomes Framing & Beginner-Friendly Onboarding"

---

# Tasks: README Outcomes Framing & Beginner-Friendly Onboarding

**Input**: Design documents from `/specs/016-readme-outcomes-and-onboarding/`

## Phase 1: User Story 1 - Outcomes-first framing, no origin story (P1) 🎯

- [x] T001 [US1] Replace the intro paragraph and "Why a rewrite" section
      with a capabilities-first intro + new "What you get" bullet list
- [x] T002 [US1] Reword Roadmap table rows 8 and 10 (the only two with
      origin-story language) to describe outcomes only
- [x] T003 [US1] Reword the `mgit`, PostgreSQL credentials, Compliance &
      observability, Java toolchain, and bulk-git-tooling section intros
      to drop "the original repo did X" framing, while keeping genuine
      third-party upstream attributions (sql-aide, git-xargs, nerd-fonts,
      surveilr/packages, etc.)
- [x] T004 [US1] Reword "Maintaining this repo with Claude Code"'s
      opening sentence (dropped the "original 7-phase rewrite" callout)
- [x] T005 [US1] Verify: grep README.md for `strategy-coach`, `successor`,
      `original repo`, `original README`, `previous generation of this
      repository` - zero matches (one unrelated hit, "big-bang rewrite
      commits", describing development methodology not repo origin, is
      correctly left alone)

**Checkpoint**: a first-time reader gets the repo's value without needing
any predecessor-project context

## Phase 2: User Story 2 - WSL-first, single-user, beginner-friendly install (P1) 🎯

- [x] T006 [US2] Rewrite Installation's opening to define Nix/flake/
      activation in one plain-language sentence each before first use
- [x] T007 [US2] Rewrite the Windows/WSL path as one linear, numbered
      walkthrough using the single-user (`--no-daemon`) Nix install -
      no `/etc/wsl.conf` edit, no systemd requirement in the main flow
- [x] T008 [US2] Move the Nerd Font step to its own section, referenced
      from the WSL walkthrough as a recommended-but-optional last step
- [x] T009 [US2] Rewrite Linux (VM/bare metal) and macOS instructions as
      concise deltas against the Windows/WSL steps rather than repeated
      full walkthroughs; keep the honest "Windows without WSL isn't
      possible" note
- [x] T010 [US2] Verify: the Windows/WSL section contains no
      `/etc/wsl.conf`/systemd step; the "Other platforms" section is
      materially shorter and delta-structured

**Checkpoint**: a first-time Windows/WSL user has one linear path to a
working, verified sandbox

## Phase 3: User Story 3 - Updating git identity and secrets from the CLI (P1) 🎯

- [x] T011 [US3] Confirm the exact current `userName`/`userEmail`
      placeholder strings in `home/git.nix` (don't assume from memory)
- [x] T012 [US3] Write the new "Updating your Git identity, and other
      secrets, from the CLI" section: git identity (`sed` one-liner) →
      `.pgpass` (CLI append) → tokens/other secrets (existing sops/age +
      direnv mechanism, condensed and simplified prose, same mechanism)
- [x] T013 [US3] Verify: run the documented `sed` command against a copy
      of the actual `home/git.nix` and confirm the exact expected diff
- [x] T014 [US3] Remove the now-superseded "Secrets & credential hygiene"
      section (folded into the new section, same content, no mechanism
      changes)

**Checkpoint**: the simplest, most common credential update (git
identity) is a single documented CLI command

## Phase 4: Polish

- [x] T015 Full top-to-bottom read-through against every acceptance
      scenario in spec.md
