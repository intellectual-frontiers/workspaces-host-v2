---

description: "Task list for AI Harness Credentials"

---

# Tasks: AI Harness Credentials

**Input**: Design documents from `/specs/022-ai-harness-credentials/`

## Phase 1: User Story 1 - AI CLIs are available after install (P1) 🎯

- [x] T001 [US1] Create `home/ai-harness.nix` (`nodejs`, `aider-chat`);
      import it from `home/default.nix`
- [x] T002 [US1] Confirm, against the real npm registry, that
      `@anthropic-ai/claude-code`, `@openai/codex`, and
      `@google/gemini-cli` exist and are actively published; note the
      binary each provides (`claude`, `codex`, `gemini`)
- [x] T003 [US1] Verify: `nix build
      .#homeConfigurations.current.activationPackage --impure` succeeds;
      `aider --version` works after activation with no extra install step

**Checkpoint**: every profile has Node.js + `aider` ready, and README
will document a verified command for the rest

## Phase 2: User Story 2 - Safe, opinionated API key setup (P1) 🎯

- [x] T004 [US2] Discover and fix a real bug found while building this
      feature's own verification: `home/secrets.nix`'s decrypt step
      didn't unwrap `sops --encrypt`'s `data:` wrapper document - add an
      `extractKey` option (default `"data"`, nullable) and apply
      `sops --decrypt --extract '["..."]'` conditionally
- [x] T005 [US2] Add the `env/`-prefixed auto-export convention to
      `home/shell.nix`'s `interactiveShellInit` (every secret under
      `~/.local/state/workspaces-host/secrets/env/` becomes an
      environment variable named after the file, in every interactive
      shell; secrets outside that prefix are unaffected)
- [x] T006 [US2] Verify the full real cycle: generate an age key, encrypt
      a fake value with `sops --encrypt --output-type yaml`, declare it
      via `local.nix` as `path = "env/ANTHROPIC_API_KEY"`, rebuild,
      activate, confirm the decrypted state file holds the bare value
      (not `data: value`), and confirm `fish -i -c` sees
      `$ANTHROPIC_API_KEY` set correctly; clean up test artifacts and
      rebuild clean afterward
- [x] T007 [US2] Re-verify the pre-existing GitHub-token pattern (no
      `env/` prefix) still decrypts to a bare value and is still NOT
      auto-exported into every shell
- [x] T008 [US2] Fix all documented `sops --encrypt` commands (README,
      `specs/004-secrets-management/quickstart.md`) to include
      `--output-type yaml`, and correct `specs/004`'s quickstart
      transcript/text to match the `extractKey` fix

**Checkpoint**: an engineer has one safe, documented way to give any AI
CLI (or any other tool) a credential ambient in every shell, verified
end-to-end against real decrypted output, not just a successful build

## Phase 3: Polish

- [x] T009 Add an "AI harness CLIs & credentials" section to
      `pkgs/doctor/doctor`: per-CLI installed/credential-present status
      for Claude Code, Codex, Gemini CLI, `aider`, plus GitHub Copilot
      CLI extension presence
- [x] T010 Add a "Setting up AI harness credentials" section to
      README.md: verified install commands, and the `env/` secret recipe
- [x] T011 Update README's Health check section to name the new doctor
      coverage
- [x] T012 Run `nix flake check --all-systems`, confirm it passes
