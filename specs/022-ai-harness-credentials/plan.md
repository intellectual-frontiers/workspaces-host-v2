# Implementation Plan: AI Harness Credentials

**Branch**: `022-ai-harness-credentials` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add a new `home/ai-harness.nix` module (Node.js + `aider-chat`) imported
by `home/default.nix`. Fix a real bug found while verifying the
opinionated "give an AI CLI its key" flow: `home/secrets.nix`'s decrypt
step didn't unwrap `sops --encrypt`'s `data:` wrapper document, so a
declared secret's plaintext file held `data: value` instead of `value`.
Add a `path = "env/..."` convention, auto-exported by `home/shell.nix`
into every interactive shell, for credentials an AI harness needs
everywhere (as opposed to the existing per-project `.envrc` pattern).
Extend `pkgs/doctor/doctor` and README to cover the new CLIs and the key
setup recipe.

## Technical Context

**Language/Version**: Nix (home-manager modules), POSIX `/bin/sh`
(`pkgs/doctor/doctor`), fish (`home/shell.nix`'s
`interactiveShellInit`).

**Primary Dependencies**: `nodejs`, `aider-chat` (both already present in
this flake's pinned nixpkgs). Claude Code/Codex/Gemini CLI are
deliberately NOT Nix dependencies - installed via `npm install -g` per
README, confirmed live against `registry.npmjs.org` rather than assumed:
`@anthropic-ai/claude-code`, `@openai/codex`, `@google/gemini-cli` all
exist and are actively published.

**Testing**: Built and activated for real in this project's own dev
sandbox (`nix build .#homeConfigurations.current.activationPackage
--impure && ./result/activate`). The `extractKey` fix was verified with a
real cycle: generated an age key, encrypted a fake value with `sops
--encrypt --output-type yaml`, declared it in `local.nix` as
`workspacesHost.secrets.test-ai-key = { sopsFile = ...; path =
"env/ANTHROPIC_API_KEY"; };`, rebuilt, activated, `cat`-inspected the
decrypted state file (bare value, no `data:` prefix), and confirmed via
`fish -i -c 'echo $ANTHROPIC_API_KEY'` that the shell auto-export picked
it up. Test artifacts (encrypted file, `local.nix` entry) were removed
and the profile rebuilt clean afterward.

**Constraints**: The `extractKey` change must not break the existing
GitHub-token secret pattern documented since feature 004 - verified by
re-reading that pattern's own decrypted output after the change.

## Constitution Check

- **Principle I**: No new flake inputs - `nodejs`/`aider-chat` come from
  the already-pinned `nixpkgs`.
- **Principle III** ("secrets never touch the agent's shell unscoped"):
  the `env/` convention is an intentional, opt-in widening (a secret the
  engineer explicitly names under `env/` becomes ambient) - the default
  (no `env/` prefix) stays scoped per-project via direnv, unchanged.
- **Principle V**: Single feature, single PR - the `extractKey` bugfix is
  included here (not split out) because it was discovered while building
  this feature's own acceptance test and this feature is what actually
  depends on the fix being correct.

No violations.

## Project Structure

```text
home/ai-harness.nix                         # new: nodejs, aider-chat
home/default.nix                            # updated: import ai-harness.nix
home/secrets.nix                            # updated: extractKey option + fix
home/shell.nix                              # updated: env/-prefixed auto-export
pkgs/doctor/doctor                          # updated: AI harness CLI + credential section
README.md                                   # updated: "Setting up AI harness credentials"
specs/004-secrets-management/quickstart.md  # updated: correct transcript + bug note
```
