# Implementation Plan: Simplify Credentials Onboarding

**Branch**: `024-simplify-credentials-onboarding` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add a tracked `credentials.example` template. Rewrite
`pkgs/workspaces-host-update/workspaces-host-update` to bootstrap
`~/.config/workspaces-host/credentials` from that template on first run,
then parse it (plain `KEY=value`, never sourced) on every subsequent
run: git identity goes into a file `home/git.nix`'s new
`programs.git.includes` picks up automatically; everything else lands in
the same per-command-scoped secrets directory `home/ai-harness.nix`'s
fish wrappers already read from (now extended to `gh`/`glab` too). Ends
by running `home-manager switch` then `doctor`. The existing sops-based
`workspacesHost.secrets` mechanism (`home/secrets.nix`) is left in place,
unchanged, reframed in docs as an optional advanced path.

## Technical Context

**Language/Version**: POSIX `/bin/sh` (`workspaces-host-update`,
`doctor`), Nix (`home/git.nix`, `home/ai-harness.nix`).

**Primary Dependencies**: None new.

**Testing**: Every piece verified for real, not just read:
- The credentials parser tested in isolation against adversarial input
  (a value with a stray shell metacharacter, an invalid line, blank
  values, quoted values, a name with spaces) with git-pull/
  home-manager-switch/doctor stubbed out, confirming exact file output.
- First-run template bootstrap and idempotent re-run both exercised
  against a fresh, isolated `$HOME`.
- Mode-600 auto-fix on a deliberately loosened credentials file.
- The full real pipeline run against this actual repo checkout end to
  end: `workspaces-host-update` with real values for `GIT_NAME`,
  `GIT_EMAIL`, `GITHUB_TOKEN`, `ANTHROPIC_API_KEY`, producing a real
  `home-manager switch` and a real `doctor` run - confirmed via
  `git config --show-origin` (isolated from this sandbox's own
  unrelated `~/.gitconfig`) that the credentials-derived identity
  actually wins, and confirmed via a stand-in `gh` executable that
  `GITHUB_TOKEN` reaches the wrapped command's invocation while staying
  empty in the ambient shell.
- `doctor`'s new GitHub/GitLab token-fallback check tested in both the
  unauthenticated and token-authenticated states with a stand-in `gh`.

**Constraints**: The parser must never `source`/`eval` file content
(injection risk from a user-edited file); a malformed line must be
skipped, not fatal; existing sops-based secrets must keep working
unmodified.

## Constitution Check

- **Principle I**: no new flake inputs.
- **Principle III**: the whole point of this feature is making the
  *easy* path also the *compliant* one - a credential from the
  credentials file is exactly as scoped (per-invocation, never ambient)
  as one from the existing sops mechanism, via the same fish-wrapper
  consumption path built in feature 023.
- **Principle V**: scoped as its own spec/PR.

No violations.

## Project Structure

```text
credentials.example                                  # new: tracked template
home/git.nix                                         # updated: programs.git.includes
home/ai-harness.nix                                  # updated: gh/glab wrapping too
home/secrets.nix                                     # updated: doc comments reframe as "advanced"
local.nix.example                                    # updated: simplified, advanced-only framing
pkgs/workspaces-host-update/workspaces-host-update   # rewritten: bootstrap + parse + wire + doctor
pkgs/doctor/doctor                                   # updated: credentials-file section, token-aware GH/GL auth
install.sh                                           # updated: closing message mentions the new step
README.md                                            # updated: "Setting up your credentials" replaces old flow
```
