# Quickstart: Core Flake + Home-Manager Module

This is the manual smoke test for this feature (there is no unit-test
framework for a Nix/dotfiles flake). Every step below was run and verified
during implementation on x86_64-linux.

## Prerequisites

- Nix installed with `nix-command` and `flakes` experimental features
  enabled (e.g. `experimental-features = nix-command flakes` in
  `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`).
- This repository checked out, all files tracked by git (flakes only see
  tracked files).

## 1. Automated check

```console
$ nix flake check
```

Expect this to complete with no errors, evaluating and building
`checks.<system>.default` (the full home-manager activation package) for
`x86_64-linux` on the machine that runs it, plus evaluating (not building)
the same for `aarch64-linux`, `x86_64-darwin`, and `aarch64-darwin` via
`nix flake check --all-systems`.

## 2. Apply the default profile (User Story 1)

```console
$ home-manager switch --flake .#default
```

If you're not on x86_64-linux, use your own system's attribute instead of
`default` (e.g. `.#aarch64-darwin`).

Verify:

```console
$ fish --version
fish, version 3.7.1

$ ls ~/.config/oh-my-posh/config.json   # generated prompt config exists

$ direnv version
2.35.0

$ ls ~/.config/direnv/lib/hm-nix-direnv.sh   # nix-direnv integration present
```

Run `home-manager switch --flake .#default` a second time with no changes:
it must report "No change so reusing latest profile generation N" rather
than creating a new generation (idempotency, SC-002).

## 3. Git identity (User Story 2)

This module's example identity is a placeholder — fork `home/git.nix` (or
override `programs.git.userName`/`userEmail` in your own module) before
relying on this for real commits.

```console
$ git config --get user.name
Workspace Engineer

$ git config --get user.email
workspace@example.invalid

$ git config --get init.defaultBranch
main

$ git config --get alias.st
status -sb
```

(Remember: a repository-local `.git/config` value always overrides this
generated global one — that's normal git precedence, not a bug in the
module.)

## 4. Ported git helper scripts (User Story 3)

```console
$ which semtag mgitstatus git-standup
~/.nix-profile/bin/semtag
~/.nix-profile/bin/mgitstatus
~/.nix-profile/bin/git-standup
```

Functional check, inside any git repository:

```console
$ git-standup                  # commits authored by you since your last working day
$ mgitstatus ~/code            # status line per repo found under ~/code
$ semtag list                  # existing vMAJOR.MINOR.PATCH tags, sorted
$ semtag final -s minor -a -m "release"   # compute + create the next minor tag
```

All three were exercised against a scratch git repository during
implementation and behaved as documented in each script's `--help`.
