---

description: "Task list for Scope AI Harness Credentials Per-Invocation"

---

# Tasks: Scope AI Harness Credentials Per-Invocation

**Input**: Design documents from `/specs/023-scope-ai-harness-credentials/`

## Phase 1: User Story 1 - An AI CLI's key never leaks into the rest of the shell (P1) 🎯

- [x] T001 [US1] Remove the shell-wide `env/` secret auto-export block
      from `home/shell.nix`'s `interactiveShellInit`
- [x] T002 [US1] Add `programs.fish.functions` wrappers for `claude`,
      `codex`, `gemini`, `aider` in `home/ai-harness.nix`: each looks for
      its known credential variable's decrypted secret file, sets it
      with `set -lx` (function-scoped, not ambient) if present, then
      calls `command <name> $argv`
- [x] T003 [US1] Update `pkgs/doctor/doctor`'s AI-harness credential
      check to also treat the decrypted secret file's existence as
      "configured," not just an already-set environment variable
- [x] T004 [US1] Rewrite README's "Setting up AI harness credentials"
      section to describe per-invocation scoping instead of shell-wide
      export; update `local.nix.example`'s comment to match
- [x] T005 [US1] Verify for real: encrypt a fake key, declare
      `path = "env/ANTHROPIC_API_KEY"`, rebuild/activate, confirm
      `fish -i -c 'echo $ANTHROPIC_API_KEY'` is empty, and confirm a
      stand-in `claude` executable invoked through the wrapper receives
      the correct value; clean up test artifacts afterward

**Checkpoint**: an AI harness credential is available only to the CLI
it's meant for, matching Constitution Principle III exactly

## Phase 2: Polish

- [x] T006 Run `nix flake check --all-systems`, confirm it passes
