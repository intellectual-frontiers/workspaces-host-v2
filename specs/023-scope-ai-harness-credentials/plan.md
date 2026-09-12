# Implementation Plan: Scope AI Harness Credentials Per-Invocation

**Branch**: `023-scope-ai-harness-credentials` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Remove feature 022's shell-wide `set -gx` auto-export of `env/`-prefixed
secrets from `home/shell.nix`. Replace it with `programs.fish.functions`
wrappers in `home/ai-harness.nix` for `claude`, `codex`, `gemini`, and
`aider` that inject a matching decrypted secret with fish's
function-scoped `set -lx`, only for that one invocation of the real
binary (via `command <name> $argv`), then update `doctor` and README to
match.

## Technical Context

**Language/Version**: Nix (home-manager modules: `home/ai-harness.nix`,
`home/shell.nix`), fish (generated wrapper functions), POSIX `/bin/sh`
(`pkgs/doctor/doctor`).

**Primary Dependencies**: None new - reuses `config.xdg.stateHome` (same
value `home/secrets.nix` already decrypts into) and home-manager's
native `programs.fish.functions` option.

**Testing**: Built and activated for real in this project's own dev
sandbox. Verified the actual regression this fixes: encrypted a fake
key, declared `path = "env/ANTHROPIC_API_KEY"`, rebuilt/activated, and
confirmed `fish -i -c 'echo $ANTHROPIC_API_KEY'` now prints nothing
(previously it printed the real value - the bug), while invoking a
stand-in `claude` executable through the generated wrapper correctly
receives the value for that one call.

**Constraints**: Must not change the GitHub-token (non-`env/`-prefixed)
secret pattern, which was already constitutionally compliant.

## Constitution Check

- **Principle III** ("secrets never touch the agent's shell unscoped"):
  this feature exists specifically to bring `env/`-prefixed AI-harness
  secrets into compliance with this principle - the fix this feature
  makes IS the constitution check passing where it previously failed.
- **Principle I**: no new flake inputs.
- **Principle V**: scoped as its own independent spec/PR rather than
  amended into feature 022's already-merged history.

No violations - this feature resolves one.

## Project Structure

```text
home/shell.nix          # updated: removed shell-wide env/ auto-export
home/ai-harness.nix     # updated: programs.fish.functions wrappers
pkgs/doctor/doctor      # updated: check secret file, not ambient env var
README.md               # updated: "Setting up AI harness credentials" corrected
local.nix.example       # updated: comment corrected
```
