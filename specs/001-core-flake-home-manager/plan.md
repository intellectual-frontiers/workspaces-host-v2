# Implementation Plan: Core Flake + Home-Manager Module

**Branch**: `001-core-flake-home-manager` | **Date**: 2026-09-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-core-flake-home-manager/spec.md`

## Summary

Replace chezmoi+Homebrew+pkgx+eget+mise+SDKMAN! with a single `flake.nix`
exposing a `homeConfigurations.default` (via home-manager's standalone,
non-NixOS mode) that declaratively provisions: Fish as the interactive
shell, oh-my-posh as the prompt, direnv+nix-direnv for per-project env
scoping, a generated `~/.gitconfig` from declarative identity options, and
three flake-packaged git helper scripts (`semtag`, `mgitstatus`,
`git-standup`) on `PATH`. `flake-utils.lib.eachDefaultSystem` covers
Linux/WSL2 and macOS. Verification is `nix flake check` plus a manual
`home-manager switch --flake .#default` smoke test.

## Technical Context

**Language/Version**: Nix expression language (flakes, `nixpkgs-unstable`
or a pinned stable channel — pin exact commit in `flake.lock`); Fish
script for any custom prompt/init glue; POSIX shell for the three ported
git helper scripts (matches their likely original implementation and
keeps them dependency-light).

**Primary Dependencies**: `nixpkgs`, `home-manager` (standalone/
non-NixOS mode), `flake-utils` for multi-system output boilerplate.
`oh-my-posh` and `fish` are both packaged in `nixpkgs` already.

**Storage**: N/A (no persistent application data; only generated dotfiles
under `$HOME`, which home-manager itself manages/backs up).

**Testing**: `nix flake check` (evaluates the flake and its `checks`
output) as the automated gate; a documented manual smoke test
(`home-manager switch --flake .#default` on a scratch `$HOME`) as the
acceptance test for the interactive-shell user stories, since asserting
"Fish opens with a themed prompt" isn't meaningfully unit-testable.

**Target Platform**: Linux (incl. WSL2) and macOS, both x86_64 and
aarch64 — four systems total via `flake-utils.lib.eachDefaultSystem`.

**Project Type**: Infrastructure-as-code / dotfiles flake (single Nix
project, no client/server split).

**Performance Goals**: N/A — this is a provisioning tool, not a runtime
service. The only relevant "performance" property is that
`home-manager switch` completes in a reasonable time on a warm Nix store
cache, which is a property of `nixpkgs`/binary caches, not this flake.

**Constraints**: Must not depend on Homebrew, pkgx, eget, mise, SDKMAN!,
or chezmoi (Constitution Principle I / Additional Constraints). Must be
buildable and checkable without network access to anything but the
standard Nix binary caches (no bespoke install scripts curl-ing
third-party binaries at activation time).

**Scale/Scope**: Single default profile for this feature (per-persona
profiles are Phase 6). Three ported helper scripts. No multi-user or
multi-host orchestration in scope.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I (Reproducible by lockfile)**: Satisfied by construction —
  every dependency (nixpkgs, home-manager, flake-utils) is a flake input
  pinned in `flake.lock`. No step in this plan resolves anything at
  install time against a mutable upstream.
- **Principle II (Ephemeral/disposable)**: Satisfied — `home-manager
  switch` from a clean checkout is the only provisioning path; there is no
  "apply once, hand-patch after" step.
- **Principle III (Secrets scoped)**: N/A for this feature — no secrets
  are introduced. Git signing-key configuration references a key ID/path
  only, per the spec's Assumptions; no key material is provisioned here.
- **Principle IV (Container/cloud-harness parity)**: This feature's
  flake outputs are structured (via `flake-utils`, and by keeping the
  home-manager module as a reusable Nix module rather than inlined
  shell) so that Phase 2 can build an OCI image from the *same* outputs
  without restructuring. Building that image is explicitly out of scope
  for this feature per the spec's Assumptions, so this is a design
  constraint on this plan, not a deliverable of it.
- **Principle V (Small independent specs)**: This plan covers exactly the
  one feature spec (001) on its own branch/PR; ported git helper scripts
  are included here (not split further) because the spec sizes them as a
  single low-priority user story (P3) within this feature, not a separate
  phase.

No violations requiring the Complexity Tracking table.

## Project Structure

### Documentation (this feature)

```text
specs/001-core-flake-home-manager/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md         # Phase 1 output (option schema, not a data model in the DB sense)
├── quickstart.md         # Phase 1 output
└── tasks.md              # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
flake.nix                        # Flake entrypoint: inputs, eachDefaultSystem outputs,
                                  # homeConfigurations.default, checks, packages
flake.lock                       # Generated; pins all inputs

home/
├── default.nix                  # Top-level home-manager module, imports the ones below
├── shell.nix                    # Fish + oh-my-posh configuration
├── direnv.nix                   # direnv + nix-direnv configuration
└── git.nix                      # Git identity options + generated ~/.gitconfig

pkgs/
├── default.nix                  # Aggregates the three derivations below for `packages.<system>`
├── semtag/
│   ├── default.nix
│   └── semtag                   # Ported script (POSIX sh)
├── mgitstatus/
│   ├── default.nix
│   └── mgitstatus
└── git-standup/
    ├── default.nix
    └── git-standup

themes/
└── oh-my-posh/default.omp.json  # Checked-in default prompt theme
```

**Structure Decision**: Single Nix project at the repo root (no
src/tests split — this is a configuration/packaging flake, not an
application). `home/*.nix` holds the home-manager module split by
concern (shell, direnv, git) so Phase 6's per-persona profiles can import
a subset later without restructuring. `pkgs/*` holds the three ported
scripts as individually buildable derivations so `nix flake check` can
build each one and `packages.<system>.<name>` stays addressable
independently (matches Principle IV's "same outputs reusable for a
container image" constraint).

## Complexity Tracking

*No constitution violations — table not needed.*
