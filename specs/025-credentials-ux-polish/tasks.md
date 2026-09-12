---

description: "Task list for Credentials UX Polish"

---

# Tasks: Credentials UX Polish

**Input**: Design documents from `/specs/025-credentials-ux-polish/`

## Phase 1: User Story 1 - Credentials file already exists after install (P1) 🎯

- [x] T001 [US1] Add a credentials-file bootstrap step to `install.sh`
      (copy `credentials.example` to
      `~/.config/workspaces-host/credentials` at mode 600 if missing;
      renumber the following "Build and activate" step)
- [x] T002 [US1] Verify in isolation: fresh `$HOME` gets the file at
      mode 600 matching the template; an existing file (with a
      deliberately modified canary value) is left untouched on a re-run

**Checkpoint**: the credentials file is ready to edit the moment
`install.sh` finishes, no extra round trip needed

## Phase 2: User Story 2 - Credentials setup is prominent (P1) 🎯

- [x] T003 [US2] Move "## Setting up your credentials" and its
      subsections to immediately after the "Installation" section
      (before "## Quickstart"), preserving content byte-for-byte
      (line-count-verified reassembly)
- [x] T004 [US2] Fix every cross-reference affected by the move: the
      "### Database passwords" section's now-forward reference to
      "PostgreSQL credentials," and confirm every other "above"/"below"
      reference (including ones outside the moved block, like "Why this
      exists") still points the correct direction
- [x] T005 [US2] Update the Windows walkthrough (step 4 mentions the
      credentials file is created; step 5 becomes "fill in your
      credentials, then apply them," replacing the old standalone
      `doctor`-only step), the "Other platforms" step-range summary, and
      "What the installer actually does" (manual steps gain the
      `mkdir`/`cp`/`chmod` equivalent)

**Checkpoint**: an engineer reads Install -> Credentials as one
continuous flow, matching what's actually necessary to do first

## Phase 3: User Story 3 - A safe `.envrc` example (P1) 🎯

- [x] T006 [US3] Add "### Making a `.envrc` work locally and in CI/CD
      (or a container)" explaining why a `.envrc` must prefer an
      already-set environment variable over the local secrets file, for
      engineers who don't yet know their code runs in more than one
      place
- [x] T007 [US3] Update the existing `AWS_ACCESS_KEY_ID` `.envrc`
      example (in "Something else that needs a credential") to already
      use the safe `${VAR:-$(cat ...)}` form, so the first example an
      engineer copies is never the unsafe one
- [x] T008 [US3] Verify for real: the fallback command is never invoked
      when the variable is already set (a canary-file test), and all
      three states (already-set, local-file fallback, neither) produce
      the documented result

## Phase 4: Polish

- [x] T009 Run `nix flake check --all-systems`, confirm it still passes
      (no Nix module touched by this feature)
