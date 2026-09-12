# Implementation Plan: Fix Login Shell Not Switching to fish, and the oh-my-posh Upgrade Nag

**Branch**: `029-fix-login-shell-and-oh-my-posh-notice` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add a best-effort `chsh` step to `install.sh` (after activation, once
fish exists at its stable home-manager-managed path), plus a matching
`doctor` check for the real login shell. Fix the oh-my-posh upgrade nag
by merging `disable_notice = true;` into `programs.oh-my-posh.settings`
in `home/shell.nix`, rather than the user's suggested `enable
autoupgrade` (rejected - see below). Document all of this, plus how to
correctly use VS Code with this setup on WSL (not a bug in this repo).

## Fish vs. bash - considered, not changed here

The user asked whether to switch the default shell to bash. Nothing
structurally *requires* fish - `home/ai-harness.nix`'s per-invocation
credential-scoping wrapper mechanism (feature 023) is the one genuine
fish-specific dependency (implemented as `programs.fish.functions`,
tested against a real fish scoping bug), and would need re-implementing
in bash's own `local`/`export` idiom; everything else (oh-my-posh, the
daily upstream-check nudge) works equivalently in bash. This plan does
not change the default shell - that's a bigger, more disruptive
decision (re-touches `home/ai-harness.nix`, `home/shell.nix`, and most
of the README) left for the user to explicitly decide, separately from
this bug fix. Recommendation communicated in chat: keep fish, since the
actual problem reported (shell not switching) is fixable directly
without abandoning it, and per this repo's "Why this exists" consistency
goal, one shell behaving identically for every engineer is worth more
than marginal familiarity with bash-flavored copy-pasted snippets.

## Technical Context

**Language/Version**: POSIX `/bin/sh` (`install.sh`, `pkgs/doctor/doctor`),
Nix (`home/shell.nix`), Markdown (README.md).

**Primary Dependencies**: None new.

**Testing**: The `chsh` logic run for real against this sandbox's own
root account (bash to fish, confirmed via `getent passwd`, idempotent
re-run confirmed, restored to bash afterward). `doctor`'s new check
tested in both states the same way. A real `nix build
.#homeConfigurations.current.activationPackage --impure` + activation
confirms `disable_notice: true` in the generated
`~/.config/oh-my-posh/config.json` and zero diff on the checked-in
theme file.

**Constraints**: `chsh` must target the stable
`$HOME/.nix-profile/bin/fish` symlink, not the raw `/nix/store/...`
path underneath it, which changes on every fish version bump and would
leave `/etc/passwd` pointing at a garbage-collectable path. Must not
abort the whole install if `chsh`/`/etc/shells` can't be modified.

## Constitution Check

- **Principle I**: `enable autoupgrade` was explicitly rejected for
  exactly this principle - a Nix-store-managed binary self-upgrading
  would either fail against the read-only store or write a binary Nix
  doesn't track. `disable_notice` changes no installed version, only a
  runtime display preference.
- **Principle V**: scoped as its own spec/PR.

No violations.

## Project Structure

```text
install.sh           # updated: best-effort chsh to fish after activation
pkgs/doctor/doctor    # updated: login-shell check (via getent, not $SHELL)
home/shell.nix        # updated: disable_notice merged into oh-my-posh settings; comment fixed
README.md             # updated: chsh/close-and-reopen note, VS Code on WSL section, doctor coverage summary
```
