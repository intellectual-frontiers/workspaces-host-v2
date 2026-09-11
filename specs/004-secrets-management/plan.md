# Implementation Plan: Secrets Management

**Branch**: `004-secrets-management` | **Date**: 2026-09-11 | **Spec**: [spec.md](./spec.md)

## Summary

Add `home/secrets.nix`: a `workspacesHost.secrets` option decrypting
declared sops files at activation time into
`$XDG_STATE_HOME/workspaces-host/secrets/`, using plain `pkgs.sops` +
`pkgs.age` (no `sops-nix` flake input - see Technical Context). Add
`pkgs/sensitivectl`: a config-driven `rclone sync` wrapper generalizing
the old `coach-sensitivectl` over any rclone remote type.

## Technical Context

**Language/Version**: Nix (home-manager module), POSIX `sh`
(`sensitivectl`, matching this repo's other ported scripts).

**Primary Dependencies**: `pkgs.sops`, `pkgs.age`, `pkgs.rclone`,
`pkgs.jq` - all already in nixpkgs, no new flake input.

Deliberately **not** using the `sops-nix` flake (the roadmap's own named
option, alongside `op`): it would add a full flake input (another
`git+https` pin) to gain a module whose core mechanism - decrypt at
activation time, write outside the Nix store - is a few lines of
home-manager `activation` DSL directly over the `sops` CLI that's already
in nixpkgs. Keeping this in-repo also keeps the whole secrets story
auditable in one small file rather than a vendored framework.

**Storage**: Decrypted secrets under `$XDG_STATE_HOME/workspaces-host/secrets/`
(not Nix store, not `$HOME` directly - `XDG_STATE_HOME` is the
already-idiomatic "machine state, not config, not cache" location
home-manager itself uses elsewhere in this repo, e.g. `xdg.stateHome`).

**Testing**: A real sops-encrypt/decrypt roundtrip against a throwaway
age key (not mocked), and a real `rclone sync` roundtrip against a
`local`-type rclone remote (no external service needed) - both documented
in `quickstart.md` with actual command transcripts from this session.

**Target Platform**: All four systems (no platform-specific logic in
either the module or the script).

**Project Type**: Additions to the existing single Nix project.

**Constraints**: Must not manage key material (Constitution Principle
III). Must be a true no-op (no packages, no activation step) when no
secrets are declared, so Phase 1-3's default profile is unaffected.

**Scale/Scope**: One home-manager module option, one CLI tool. Actual
secret *values* and `sensitivectl` *profiles* are per-engineer, per-machine
data this feature deliberately does not check into the repo or manage
declaratively.

## Constitution Check

- **Principle I**: No new flake inputs; `sops`/`age`/`rclone`/`jq` are
  pinned by the same `flake.lock` as everything else.
- **Principle II**: Decryption re-runs on every activation (no cached
  state to go stale); `sensitivectl` profiles are just config, rebuilt
  from source-of-truth (the remote or the local dir) on every
  backup/restore.
- **Principle III**: This feature's entire design is in service of this
  principle - see spec Edge Cases and FR-005.
- **Principle IV**: `sensitivectl` lands in `home.packages` like
  everything else, so Phase 2's OCI image gets it automatically; the
  secrets module only activates when a caller declares secrets, which a
  container build typically wouldn't (no key material inside an image).
- **Principle V**: Single feature, single PR.

No violations.

## Project Structure

```text
home/secrets.nix                    # workspacesHost.secrets option + activation script

pkgs/sensitivectl/
├── default.nix
└── sensitivectl

specs/004-secrets-management/
├── plan.md
├── quickstart.md
└── tasks.md
```

**Structure Decision**: `home/secrets.nix` follows the existing
`home/*.nix` per-concern split; `pkgs/sensitivectl/` follows the existing
`pkgs/<name>/{default.nix,<name>}` layout used by `semtag`/`mgitstatus`/
`git-standup`.

## Complexity Tracking

*No constitution violations - table not needed.*
