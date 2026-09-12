# Feature Specification: Compliance & Observability Tooling

**Feature Branch**: `011-compliance-observability-tooling`

**Created**: 2026-09-12

**Status**: Draft

**Input**: Gap analysis comparing `workspaces-host-v2` against
`strategy-coach/workspaces-host` found that the original README's SOC2/
compliance paragraph (`osquery`, `cnquery`, `steampipe` for system/endpoint
observability; `OpenObserve` for metrics/tracing/logging) and its
`eget`-installed `surveilr` binary (`surveilr/packages`, "Resource
Surveillance and Integration Engine") were both dropped by the rewrite -
none of these five tools exist anywhere in `workspaces-host-v2` today.

## Background

`strategy-coach/workspaces-host` documented (`README.md`) that it used
"`osQuery`, `cnquery`, `steampipe`, et. al. system and endpoint
observability tools for SOC2 and other compliance requirements" and
"`OpenObserve` for metrics, tracing, logging and similar application
lifecycle observability." Of these, only `osquery` had an actual install
path in the repo (`dot_strategy-coach/executable_finalize-setup.tmpl`,
fetching the latest Debian package directly from `pkg.osquery.io`) - the
repo's own `doctor.ts` also checked for `osqueryi`, `surveilr`, and
`openobserve` on `PATH`, but `cnquery`/`steampipe` were prose-only,
presumably left to Homebrew/pkgx on a case-by-case basis. `surveilr` (from
`surveilr/packages`'s GitHub releases) was installed via the repo's
`dot_eget.toml.tmpl`.

This feature makes all five natively available in `workspaces-host-v2`:
`osquery`, `cnquery`, `steampipe`, and `openobserve` are all packaged in
this flake's pinned nixpkgs (`nixos-24.11`); `surveilr` is not, and is
packaged here as a prebuilt-binary derivation from its GitHub releases,
the same category of port `pkgs/backlog-md` already established for a
third-party binary this flake's nixpkgs doesn't carry.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Endpoint/system observability tools on PATH (Priority: P1)

An engineer provisioning this flake gets `osqueryi`, `cnquery`, and
`steampipe` on `PATH` without installing anything extra, so SOC2-style
"what does this box actually look like" questions can be answered the
moment the environment is up.

**Why this priority**: These three are the original README's own named
SOC2/compliance tools - the core capability this feature restores.

**Independent Test**: After activation, run `osqueryi --version` (Linux
only), `cnquery version`, and `steampipe --version`; each prints a
version string with exit code 0.

**Acceptance Scenarios**:

1. **Given** a fresh activation on `x86_64-linux` or `aarch64-linux`,
   **When** `osqueryi --version` runs, **Then** it prints a version and
   exits 0.
2. **Given** a fresh activation on any of this flake's four supported
   systems, **When** `cnquery version` and `steampipe --version` run,
   **Then** both print a version and exit 0.
3. **Given** a fresh activation on `x86_64-darwin`/`aarch64-darwin`,
   **When** `doctor` runs, **Then** it reports `osquery`'s absence as an
   informational WARN (nixpkgs packages it Linux-only), not a FAIL.

---

### User Story 2 - Application-lifecycle observability (`OpenObserve`) (Priority: P2)

An engineer who wants to ingest and query their own
metrics/traces/logs has `openobserve` available on `PATH` across all four
supported systems, without a from-scratch build or a manual download.

**Why this priority**: The original README's second named category
(application-lifecycle observability, distinct from endpoint/system
auditing) - real but secondary to User Story 1's SOC2-focused tools.

**Independent Test**: After activation, run `openobserve --version` on
each of the four supported systems; it prints a version and exits 0.

**Acceptance Scenarios**:

1. **Given** a fresh activation on any supported system, **When**
   `openobserve --version` runs, **Then** it prints a version and exits 0.
2. **Given** `openobserve` is on `PATH`, **When** nothing further is
   done, **Then** no background service is started - it's a binary an
   engineer chooses to run, not a daemon this repository launches for
   them.

---

### User Story 3 - Resource surveillance evidence capture (`surveilr`) (Priority: P2)

An engineer on a system where surveilr publishes a binary
(`x86_64-linux`, `x86_64-darwin`) gets `surveilr` on `PATH`; on a system
where it doesn't (`aarch64-linux`, `aarch64-darwin`), the flake still
evaluates and builds cleanly, and `doctor` reports the absence as an
informational WARN rather than the flake failing outright.

**Why this priority**: A real capability gap (the original's `eget`
install, silently dropped) but narrower in reach than User Stories 1-2
since it's genuinely only published for two of this flake's four systems.

**Independent Test**: On `x86_64-linux`, after activation, run
`surveilr --version`; it prints a version and exits 0. On
`aarch64-linux`/`aarch64-darwin`, confirm `nix build
.#homeConfigurations.<that-system>.activationPackage` still succeeds and
`surveilr` is simply absent from the resulting profile.

**Acceptance Scenarios**:

1. **Given** an activation on `x86_64-linux` or `x86_64-darwin`, **When**
   `surveilr --version` runs, **Then** it prints a version and exits 0.
2. **Given** an activation on `aarch64-linux` or `aarch64-darwin`,
   **When** the home configuration is built, **Then** it succeeds without
   `surveilr` on `PATH`, and `doctor` reports this as a WARN.

### Edge Cases

- `osquery`'s nixpkgs package sets `meta.platforms = platforms.linux`
  (an actual eval-time restriction, not just documentation) - referencing
  it unconditionally in `home.packages` on Darwin would break evaluation
  there, so it MUST be added conditionally (mirroring how
  `pkgs/default.nix` already excludes the Linux-only `init-firewall` from
  its cross-platform aggregate).
- `surveilr`'s upstream release assets exist only for `x86_64-linux`
  (tar.gz) and `x86_64-darwin` (zip) - no `aarch64` asset of either kind.
  The package MUST be present in this flake's package set only for those
  two systems, not throw an unconditional error that would break `nix
  flake check --all-systems` on the other two.
- `cnquery`, `steampipe`, and `openobserve` have no platform restriction
  in nixpkgs (verified against this flake's exact pinned `nixos-24.11`
  commit) and are added unconditionally.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `home/tools.nix` MUST add `cnquery`, `steampipe`, and
  `openobserve` (plain nixpkgs packages) to its existing `home.packages`
  list, installed on every profile across all four supported systems.
- **FR-002**: `home/tools.nix` MUST add nixpkgs' `osquery` to
  `home.packages` conditionally, only when
  `pkgs.stdenv.hostPlatform.isLinux` is true.
- **FR-003**: A new `pkgs/surveilr` package MUST fetch the `surveilr`
  binary from its GitHub releases (`surveilr/packages`) via `fetchurl`,
  install it at `$out/bin/surveilr`, and be registered in
  `pkgs/default.nix`'s aggregate conditionally, only for
  `x86_64-linux`/`x86_64-darwin` (the two systems with a published
  asset) - mirroring `pkgs/default.nix`'s existing documented exclusion
  of `init-firewall` for a platform-restricted tool.
- **FR-004**: `pkgs/doctor/doctor` MUST report `osqueryi`, `cnquery`,
  `steampipe`, `openobserve`, and `surveilr` on `PATH`, treating
  `osquery`'s absence on Darwin and `surveilr`'s absence on
  `aarch64-linux`/`aarch64-darwin` as informational WARNs rather than
  FAILs.
- **FR-005**: README.md MUST document what each of the five tools is for,
  that they're installed on `PATH` by every profile, and the two
  platform caveats (osquery Linux-only, surveilr missing on aarch64),
  matching this repo's existing terse, factual documentation voice.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix build .#homeConfigurations.default.activationPackage`
  succeeds with all five tools included (four unconditionally, `osquery`
  on Linux).
- **SC-002**: `nix flake check --all-systems` passes on all four systems,
  including `aarch64-linux`/`aarch64-darwin`, where `osquery` and
  `surveilr` are simply absent from the built closure rather than causing
  an evaluation failure.
- **SC-003**: A real activation on `x86_64-linux` puts `osqueryi`,
  `cnquery`, `steampipe`, `openobserve`, and `surveilr` on `PATH`, and
  each tool's version/help invocation exits 0.
- **SC-004**: `doctor` reports all five tools accurately, including the
  two platform-conditional WARNs.

## Assumptions

- Verified directly against this flake's exact pinned `nixpkgs` commit
  (`nixos-24.11`, rev `50ab793786d9de88ee30ec4e4c24fb4236fc2674`):
  `cnquery` (`pkgs/by-name/cn/cnquery`) and `steampipe`
  (`pkgs/by-name/st/steampipe`) declare no `meta.platforms`/
  `meta.badPlatforms` restriction; `openobserve`
  (`pkgs/servers/monitoring/openobserve`) likewise, and its `default.nix`
  already conditionally wires in Apple SDK frameworks for Darwin, meaning
  upstream nixpkgs itself intends Darwin support; `osquery`
  (`pkgs/tools/system/osquery`) sets `meta.platforms = platforms.linux`
  explicitly.
- `surveilr`'s real GitHub releases (`surveilr/packages`, tag `3.63.0`
  at the time of this feature) were inspected directly: assets are
  `surveilr_3.63.0_x86_64-unknown-linux-gnu.tar.gz` and
  `surveilr_3.63.0_x86_64-apple-darwin.zip` (plus a Windows zip, two
  `.deb`s, and a `.rb` Homebrew formula, none relevant here) - no
  `aarch64` asset of either OS exists, so `pkgs/surveilr` only ever
  resolves a URL for those two systems.
- `cnquery`/`steampipe`/`openobserve` are Go/Rust builds that could be
  slow from source; `steampipe` and `openobserve` are indeed served
  prebuilt from `cache.nixos.org`. `cnquery` is not: nixpkgs marks it
  unfree (`bsl11` - Mondoo's Business Source License), and Hydra does not
  build/cache unfree packages, so `cnquery` always builds from source
  regardless of substituters. Building it from source requires a) opting
  into its unfree license explicitly (`flake.nix`'s `pkgsFor` now sets
  `config.allowUnfreePredicate` scoped to just `"cnquery"`, rather than a
  blanket `allowUnfree = true`) and b) fetching its tagged source tree -
  nixpkgs' `cnquery` derivation does this with `fetchFromGitHub` (a
  sandboxed fixed-output derivation build), which `pkgs/specify-cli`'s
  own derivation already documents as unreliable in a sandbox whose
  egress proxy the *build sandbox's* own curl can't TLS-validate the way
  the outer `nix` CLI process can. `home/tools.nix` therefore overrides
  `cnquery`'s `src` with `builtins.fetchGit` pinned to the exact
  `v11.19.1` tag commit, the same technique `specify-cli` already uses
  for the identical class of problem - `vendorHash` is untouched since
  the fetched tree is byte-identical to the tagged release archive
  (verified: the Go module vendoring and build both completed
  successfully against it).
