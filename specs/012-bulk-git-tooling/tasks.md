---

description: "Task list for Bulk Multi-Repo Git Tooling"

---

# Tasks: Bulk Multi-Repo Git Tooling

**Input**: Design documents from `/specs/012-bulk-git-tooling/`

## Phase 1: User Story 1 - Everyday git subcommands (`git-extras`) (P1) 🎯

- [x] T001 [US1] Verify against this flake's exact pinned `nixpkgs`
      commit that `git-extras` sets `meta.platforms = platforms.all`
- [x] T002 [US1] Add `git-extras` to `home/tools.nix`'s `home.packages`
      (plain nixpkgs package, unconditional)
- [x] T003 [US1] Verify: `nix build
      .#homeConfigurations.default.activationPackage` succeeds
- [x] T004 [US1] Verify: real activation puts `git-extras` on `PATH`;
      `git extras --version` exits 0

**Checkpoint**: baseline `git-extras` subcommands are on `PATH` by
default

## Phase 2: User Story 2 - Bulk changes across many repos (`git-xargs`) (P1) 🎯

- [x] T005 [US2] Inspect `gruntwork-io/git-xargs`'s real GitHub releases
      to confirm exact asset names/platforms (all four supported systems
      publish a plain, unarchived binary)
- [x] T006 [US2] Get real `sha256` hashes for all four per-system assets
      via `nix store prefetch-file`
- [x] T007 [US2] Create `pkgs/git-xargs/default.nix` (per-system asset
      map, `fetchurl` + `stdenvNoCC.mkDerivation`, `dontUnpack = true`,
      direct `install -Dm755`)
- [x] T008 [US2] Register `git-xargs` in `pkgs/default.nix`'s aggregate
      (unconditional - a real asset exists for all four systems)
- [x] T009 [US2] Verify: `nix build
      .#homeConfigurations.default.activationPackage` still succeeds;
      real activation puts `git-xargs` on `PATH`, `git-xargs --help`
      exits 0

**Checkpoint**: `git-xargs` is on `PATH` by default (unlike the original
repo, where it was opt-in)

## Phase 3: Polish

- [x] T010 Add `git-extras`/`git-xargs` to `pkgs/doctor/doctor`'s
      existing ported-tools check loop
- [x] T011 Add README.md "Bulk changes across many repos" subsection
      (under the existing `mgit` section) and a roadmap row
- [x] T012 Run `nix flake check --all-systems`, confirm it passes

## Verification transcript

`nix build .#homeConfigurations.default.activationPackage -L` succeeded.
A real activation (`./result/activate`, `USER=workspace`,
`HOME=/home/workspace`) put both tools on `PATH`:

```console
$ git extras --version
7.3.0

$ git-xargs --help
Usage: git-xargs [--loglevel] [--github-org] [--draft] [--dry-run] ...
git-xargs is a command-line tool (CLI) for making updates across
multiple Github repositories with a single command.
```

`doctor`'s ported-tools loop reports both:

```console
PASS  git-extras is on PATH (/home/workspace/.nix-profile/bin/git-extras)
PASS  git-xargs is on PATH (/home/workspace/.nix-profile/bin/git-xargs)

doctor: all checks passed (WARNs, if any, are informational)
```

`nix flake check --all-systems` passed (exit 0).

**Complication encountered and resolved**: the first build failed with a
`home-manager-path` file collision - nixpkgs' `git-extras` bundles its
own `bin/git-standup`, which collides with this repo's own,
already-ported `pkgs/git-standup` (a different, native implementation).
Fixed by wrapping `git-extras` in `pkgs.lib.lowPrio` in `home/tools.nix`,
so this repo's own `git-standup` wins the collision - verified post-fix
that `which git-standup` resolves to the repo's own port
(`pkgs/git-standup`'s binary), not git-extras' bundled one, and every
other `git-extras` subcommand is unaffected.
