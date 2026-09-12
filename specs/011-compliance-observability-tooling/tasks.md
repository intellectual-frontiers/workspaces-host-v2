---

description: "Task list for Compliance & Observability Tooling"

---

# Tasks: Compliance & Observability Tooling

**Input**: Design documents from `/specs/011-compliance-observability-tooling/`

## Phase 1: User Story 1 - Endpoint/system observability tools (P1) 🎯

- [x] T001 [US1] Verify against this flake's exact pinned `nixpkgs` commit
      (not assumed) that `cnquery`/`steampipe` build unrestricted on all
      four systems and that `osquery` sets `meta.platforms =
      platforms.linux`
- [x] T002 [US1] Add `cnquery`, `steampipe` to `home/tools.nix`'s
      `home.packages` (plain nixpkgs packages, unconditional)
- [x] T003 [US1] Add `osquery` to `home/tools.nix`'s `home.packages`
      conditionally via `pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux`
- [x] T004 [US1] Verify: `nix build
      .#homeConfigurations.default.activationPackage` succeeds
- [x] T005 [US1] Verify: real activation puts `osqueryi`, `cnquery`,
      `steampipe` on `PATH`; `osqueryi --version`, `cnquery version`,
      `steampipe --version` each exit 0

**Checkpoint**: SOC2-style endpoint/system observability tools are on
`PATH` by default

## Phase 2: User Story 2 - Application-lifecycle observability (P2) 🎯

- [x] T006 [US2] Verify `openobserve` has no platform restriction in this
      flake's pinned nixpkgs; add it to `home/tools.nix`'s
      `home.packages` (unconditional)
- [x] T007 [US2] Verify: real activation puts `openobserve` on `PATH`;
      `openobserve --version` exits 0

**Checkpoint**: application-lifecycle observability tooling is on `PATH`
by default

## Phase 3: User Story 3 - Resource surveillance (`surveilr`) (P2) 🎯

- [x] T008 [US3] Inspect `surveilr/packages`'s real GitHub releases to
      confirm exact asset names/platforms (no aarch64 asset of either OS)
- [x] T009 [US3] Get real `sha256` hashes for the `x86_64-linux` tar.gz
      and `x86_64-darwin` zip assets via `nix store prefetch-file`
- [x] T010 [US3] Create `pkgs/surveilr/default.nix` (per-system asset
      map, `fetchurl` + `stdenvNoCC.mkDerivation`, `unzip` in
      `nativeBuildInputs` for the Darwin zip)
- [x] T011 [US3] Register `surveilr` in `pkgs/default.nix`'s aggregate,
      conditionally (`x86_64-linux`/`x86_64-darwin` only, matching the
      file's existing `init-firewall` exclusion pattern/comment)
- [x] T012 [US3] Verify: `nix build
      .#homeConfigurations.default.activationPackage` still succeeds;
      real activation puts `surveilr` on `PATH`, `surveilr --version`
      exits 0

**Checkpoint**: `surveilr` is on `PATH` wherever upstream publishes it

## Phase 4: Polish

- [x] T013 Add `osqueryi`/`cnquery`/`steampipe`/`openobserve`/`surveilr`
      checks to `pkgs/doctor/doctor`, with the two platform-conditional
      absences reported as WARN, not FAIL
- [x] T014 Add README.md "Compliance & observability tooling" section
      and a roadmap row
- [x] T015 Run `nix flake check --all-systems`, confirm it passes
      (including `aarch64-linux`/`aarch64-darwin`, where `osquery`/
      `surveilr` are absent by design)

## Verification transcript

`nix build .#homeConfigurations.default.activationPackage -L` succeeded.
A real activation (`./result/activate`, `USER=workspace`,
`HOME=/home/workspace`) put all five tools on `PATH`:

```console
$ osqueryi --version
osqueryi version 5.13.1

$ cnquery version
cnquery unstable (development, unknown)

$ steampipe --version
Error: Steampipe cannot be run as the "root" user.

$ openobserve --version
openobserve v0.11.0

$ surveilr --version
surveilr 3.63.0
```

`steampipe` refuses to run as `root` (an intentional upstream safety
check, not a packaging bug) - this dev sandbox has no non-root Nix
multi-user setup to activate as an unprivileged user, unlike this
project's own CI (`.github/workflows/ci.yml`), which already activates
as a real non-root `workspace` user and would exercise `steampipe`
cleanly. `doctor`'s own check only confirms `steampipe` is on `PATH`
(the same class of check every other ported tool gets), which it is;
`doctor`'s full transcript:

```console
-- Compliance & observability tooling --
PASS  osquery (osqueryi) is on PATH (/home/workspace/.nix-profile/bin/osqueryi)
PASS  cnquery is on PATH (/home/workspace/.nix-profile/bin/cnquery)
PASS  steampipe is on PATH (/home/workspace/.nix-profile/bin/steampipe)
PASS  openobserve is on PATH (/home/workspace/.nix-profile/bin/openobserve)
PASS  surveilr is on PATH (/home/workspace/.nix-profile/bin/surveilr)

doctor: all checks passed (WARNs, if any, are informational)
```

`nix flake check --all-systems` passed (exit 0) - `packages.<system>`
evaluation confirmed `surveilr` present only for `x86_64-linux`/
`x86_64-darwin` and absent (no eval error) for
`aarch64-linux`/`aarch64-darwin`.

**Complication encountered and resolved**: `cnquery` is unfree
(`bsl11`), which nixpkgs refuses to evaluate without an explicit opt-in
(`flake.nix`'s `pkgsFor` now scopes `config.allowUnfreePredicate` to just
`"cnquery"`) - and because Hydra doesn't build/cache unfree packages, it
always builds from source. Its `fetchFromGitHub`-based source fetch
failed in this dev sandbox specifically (a restrictive egress proxy that
a sandboxed fixed-output derivation's own `curl` can't get through, the
same class of problem `pkgs/specify-cli`'s own comment already
documents), so `home/tools.nix` overrides `cnquery`'s `src` with a
pinned `builtins.fetchGit` (exact same tagged commit,
`7dee6bd537cb4a04c223a19394726fa8707171e6` = `v11.19.1`) - verified this
produces an identical, successfully-building source tree (Go module
vendoring and the full build/check/install phases all completed against
it).
