---

description: "Task list for Simplify Credentials Onboarding"

---

# Tasks: Simplify Credentials Onboarding

**Input**: Design documents from `/specs/024-simplify-credentials-onboarding/`

## Phase 1: User Story 1 - One file, one command (P1) 🎯

- [x] T001 [US1] Add tracked `credentials.example` template covering
      `GIT_NAME`, `GIT_EMAIL`, `GITHUB_TOKEN`, `GITLAB_TOKEN`,
      `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`
- [x] T002 [US1] Rewrite `workspaces-host-update`: bootstrap the
      credentials file from the template (mode 600) on first run and
      stop; on subsequent runs, defensively re-assert mode 600, parse
      the file as plain `KEY=value` (never sourced), and continue
- [x] T003 [US1] Verify the parser in isolation: comments/blank
      lines/invalid lines skipped, quoted values unquoted, a value with
      a shell metacharacter never executed, blank values ignored
- [x] T004 [US1] Verify first-run bootstrap and idempotent re-run
      against a fresh, isolated `$HOME`
- [x] T005 [US1] Verify mode-600 auto-fix after deliberately loosening
      the credentials file's permissions
- [x] T006 [US1] Have `workspaces-host-update` run `home-manager switch`
      then `doctor` as its last two steps

**Checkpoint**: filling in one plain-text file and running one command
sets up an engineer's identity and credentials, with an immediate
pass/warn/fail report

## Phase 2: User Story 2 - A credential never becomes shell-wide (P1) 🎯

- [x] T007 [US2] Add `programs.git.includes` to `home/git.nix`, pointing
      at a fixed path `workspaces-host-update` generates - relying on
      git's own silent no-op when the include target doesn't exist yet
- [x] T008 [US2] Extend `home/ai-harness.nix`'s per-invocation wrapper
      mechanism (built in feature 023) to `gh` and `glab`, using
      `GITHUB_TOKEN`/`GH_TOKEN` and `GITLAB_TOKEN` respectively
- [x] T009 [US2] Have `workspaces-host-update` write `GIT_NAME`/
      `GIT_EMAIL` into that include file, and every other recognized
      key into the same `secrets/env/<NAME>` directory the wrappers read
- [x] T010 [US2] Update `pkgs/doctor/doctor`'s GitHub/GitLab section to
      retry `gh auth status`/`glab auth status` with the matching token
      scoped to just that one check when plain auth fails, and add a
      "Credentials file" section reporting existence/permissions
- [x] T011 [US2] Verify for real, end to end, against this actual repo
      checkout: real `GIT_NAME`/`GIT_EMAIL`/`GITHUB_TOKEN`/
      `ANTHROPIC_API_KEY` values through the full
      `workspaces-host-update` pipeline (real `git pull`, real
      `home-manager switch`, real `doctor`); confirmed via
      `git config --show-origin` (with this sandbox's own unrelated
      `~/.gitconfig` temporarily moved aside) that the credentials-file
      identity resolves correctly; confirmed via a stand-in `gh`
      executable that `GITHUB_TOKEN` reaches the wrapped invocation
      while staying unset in the ambient shell; confirmed `doctor`'s
      token-aware GitHub check in both states

**Checkpoint**: the simpler path is exactly as constitutionally
compliant (no ambient shell-wide secrets) as the sops-based one it
supplements

## Phase 3: Polish

- [x] T012 Reframe `home/secrets.nix`'s docs and `local.nix.example` as
      the advanced, opt-in, field-level-encryption-at-rest path
- [x] T013 Rewrite README's git-identity/secrets sections around
      "Setting up your credentials"; update the AI-harness-credentials
      section's mechanism description; update `install.sh`'s closing
      message and the Health check section's doctor-coverage summary
- [x] T014 Clean up all test credentials/secrets/git-identity artifacts
      from this sandbox and confirm a clean rebuild + activation
- [x] T015 Run `nix flake check --all-systems`, confirm it passes
