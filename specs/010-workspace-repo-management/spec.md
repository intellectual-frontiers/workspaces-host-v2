# Feature Specification: Workspace Repo Management (mgit)

**Feature Branch**: `010-workspace-repo-management`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "For #1 just take the exact same functionality and put into workspaces-host-v2 so that a separate repo is not necessary, all the same functionalities of strategy-coach/workspaces will be native to the workspaces-host-v2 repo."

## Background

`strategy-coach/workspaces-host` (the original repo this project succeeds)
never itself provisioned a way to clone an engineer's actual repos - it
depended on a *second*, separate repo,
[`strategy-coach/workspaces`](https://github.com/strategy-coach/workspaces),
whose `mgit.ts`/`ws-ensure.ts` Deno scripts a user had to clone alongside
`workspaces-host`, copy `ws-ensure.ts` into `~/workspaces`, and edit by hand
to declare which repos to track. That's the single biggest capability gap
identified when auditing `workspaces-host-v2` against the original two-repo
system (see the gap analysis that prompted this feature) - a provisioned
shell/prompt/toolchain with no reproducible way to get actual repos onto
disk.

This feature makes that functionality native: no second repo, no Deno
runtime, one `mgit` command installed by every profile alongside a
`~/workspaces` directory bootstrapped on first activation.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Clone-or-pull repos by a governed host/org/repo layout (Priority: P1)

An engineer declares a list of `host.tld/org/repo` strings once, then runs
one idempotent command any time they want their local `~/workspaces` to
reflect that list - freshly cloning anything new, pulling anything that
already exists - without ever worrying about where on disk a given repo
should live.

**Why this priority**: This is the actual `mgit.ts`/`ws-ensure.ts`
capability being ported - the reason this feature exists.

**Independent Test**: Configure `~/workspaces/mgit.json` with a real public
repo; run `mgit ensure`; confirm it's cloned at
`~/workspaces/<host>/<org>/<repo>`; run `mgit ensure` again and confirm it
pulls instead of re-cloning (no error, no duplicate clone).

**Acceptance Scenarios**:

1. **Given** an empty `~/workspaces` and a `mgit.json` listing one repo,
   **When** `mgit ensure` runs, **Then** that repo is cloned at
   `~/workspaces/<git-host>/<org>/<repo>`.
2. **Given** that repo already cloned, **When** `mgit ensure` runs again,
   **Then** it runs `git pull --quiet` instead of cloning again, and exits
   without error.
3. **Given** a `mgit.json` entry with `"fresh": true` for an
   already-cloned repo, **When** `mgit ensure` runs, **Then** the existing
   clone is deleted and freshly re-cloned instead of pulled.
4. **Given** a `mgit.json` entry for a repo that fails to clone (bad URL,
   network error), **When** `mgit ensure` runs, **Then** that failure is
   reported but does not stop the remaining repos in the list from being
   processed.

---

### User Story 2 - VS Code multi-root "monorepo" composition (Priority: P2)

An engineer whose cloned repos contain `*.mgit.code-workspace` files (VS
Code multi-root workspace definitions listing other `mgit`-managed repos
as `folders`) gets those dependent repos cloned automatically, and gets a
symlink at the workspace root so the composed workspace can be opened from
one place regardless of which repo it physically lives in.

**Why this priority**: A real capability of the original `mgit.ts`
(`symlinkMgitVsCodeWs` + `ensureVsCodeWsDepRepos`), but secondary to the
core clone-or-pull loop - many users will only ever need User Story 1.

**Independent Test**: Clone a repo containing a `*.mgit.code-workspace`
file whose `folders[].path` references another repo path; run
`mgit ensure`; confirm the workspace file is symlinked to `~/workspaces`
and the referenced repo is also cloned.

**Acceptance Scenarios**:

1. **Given** a cloned repo containing `some.mgit.code-workspace`, **When**
   `mgit ensure` processes that repo, **Then** a symlink to that file
   appears at `~/workspaces/some.mgit.code-workspace`.
2. **Given** that workspace file's `folders[].path` lists other repo
   paths, **When** `mgit ensure` processes it, **Then** each listed repo
   is also cloned-or-pulled (recursively, so a chain of dependent
   workspace files all resolve), and a repo already handled in the same
   run is not re-processed (no infinite loop on repos that reference each
   other).

---

### User Story 3 - Status and inspection across the whole workspace (Priority: P2)

An engineer can see, at a glance, which of their many cloned repos are
dirty, ahead/behind, or missing an upstream, and which git hosts/repos are
referenced by the workspace's `*.mgit.code-workspace` files, without
having to `cd` into each one individually.

**Why this priority**: Read-only reporting the original also provided
(`mGitStatus`/`inspect`); valuable but not blocking for the core
clone-management workflow.

**Independent Test**: Run `mgit status` and `mgit inspect` against a
`~/workspaces` with a mix of clean/dirty repos and confirm accurate,
per-repo output.

**Acceptance Scenarios**:

1. **Given** a `~/workspaces` with a dirty repo and a clean repo, **When**
   `mgit status` runs, **Then** it reports each repo's path, branch, and
   status flags (clean/dirty/ahead/behind/no-upstream).
2. **Given** `*.mgit.code-workspace` files under `~/workspaces`, **When**
   `mgit inspect` runs, **Then** it prints the distinct git hosts and the
   full list of repos those files reference.

---

### Edge Cases

- A repo referencing itself, or two repos referencing each other, in their
  `*.mgit.code-workspace` `folders`, must not infinite-loop - a per-run
  "already handled" set (keyed by absolute path) prevents this, mirroring
  `mgit.ts`'s own `wsContext.handled` array.
- `~/workspaces/mgit.json` is per-user declared state (which repos to
  track) - home-manager creates it once, empty, if absent, and never
  overwrites an existing one, the same category of file as `home/git.nix`
  identity overrides or `sensitivectl`'s config.
- This feature does not implement `ws-ensure.ts`'s original TypeScript
  array-literal config format - `mgit.json` (JSON) is the native
  equivalent, since there's no Deno runtime in this repo to execute a
  `.ts` config against.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A new `mgit` package (`pkgs/mgit`) MUST provide `ensure`,
  `status`, and `inspect` subcommands, installed by every profile via the
  existing `pkgs/default.nix` → `home/tools.nix` aggregation (same
  mechanism as `semtag`/`mgitstatus`/etc.).
- **FR-002**: `mgit ensure` MUST clone a repo listed in `$MGIT_CONFIG`
  (default `~/workspaces/mgit.json`) to
  `$WORKSPACES_HOME/<repo-path>` (default `$WORKSPACES_HOME` =
  `~/workspaces`) if absent, or `git pull --quiet` it if already present,
  unless that entry sets `"fresh": true`, in which case the existing clone
  is deleted and re-cloned.
- **FR-003**: `mgit ensure` MUST, after cloning/pulling a repo, find any
  files matching `$MGIT_VSCODE_WS_PATTERN` (default
  `*.mgit.code-workspace`) inside it, symlink each to
  `$WORKSPACES_HOME`, parse its `folders[].path` entries, and recursively
  `ensure` each referenced repo path - deduplicated per run so repos that
  reference each other do not infinite-loop.
- **FR-004**: `mgit status` MUST report git status (dirty / ahead / behind
  / no-upstream / clean) for every repo found under `$WORKSPACES_HOME`
  (delegating to the already-ported `mgitstatus` tool rather than
  duplicating its logic).
- **FR-005**: `mgit inspect` MUST list the distinct git hosts and the full
  set of repo paths referenced by `$MGIT_VSCODE_WS_PATTERN` files under
  `$WORKSPACES_HOME`.
- **FR-006**: `home/workspaces.nix` MUST create `~/workspaces` and an
  empty `~/workspaces/mgit.json` (`{"repos": []}`) on first activation via
  `home.activation`, without ever overwriting an existing `mgit.json`.
- **FR-007**: `pkgs/doctor/doctor` MUST report whether `mgit` is on PATH
  and whether `~/workspaces` and `~/workspaces/mgit.json` exist.
- **FR-008**: README.md MUST document the governed directory convention,
  the `mgit.json` config format, the three subcommands, and the VS Code
  multi-root composition feature, replacing the original's two-repo
  (`workspaces-host` + `workspaces`) setup instructions with this repo's
  single-repo equivalent.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix build .#homeConfigurations.default.activationPackage`
  succeeds with `mgit` and `home/workspaces.nix` included.
- **SC-002**: A real activation creates `~/workspaces/mgit.json` (empty
  `repos` list) without requiring any manual step.
- **SC-003**: Against a real public git repo, `mgit ensure` clones it to
  the documented path, a second `mgit ensure` run pulls instead of
  re-cloning, and `mgit status`/`mgit inspect` produce accurate output.
- **SC-004**: A synthetic `*.mgit.code-workspace` file with `folders`
  entries (including a cycle back to itself) is symlinked correctly and
  its referenced repos are recursively resolved exactly once each, with
  no infinite loop and no crash on an intentionally-invalid referenced
  repo path.
- **SC-005**: `nix flake check --all-systems` continues to pass.

## Assumptions

- JSON (not the original's TypeScript array literal, and not JSONC) is
  the native config format - VS Code `*.code-workspace` files themselves
  may use JSONC in principle, but every real-world example in the
  original repo's own README and this feature's own test fixtures is
  comment-free JSON, so `jq` (already a dependency of other ported tools
  in this repo) is sufficient without a JSONC-aware parser.
- Reimplementing in POSIX shell (matching this repo's established
  `pkgs/mgitstatus`/`pkgs/sensitivectl` convention) rather than vendoring
  the original Deno/TypeScript source is the right call for a Nix-first
  repo: it avoids provisioning a Deno runtime and the reproducibility
  complications of a Nix derivation fetching third-party HTTP-imported
  TypeScript dependencies (`deno.land/std`, `dax`) at build time, while
  preserving the exact same directory convention, idempotent
  clone-or-pull behavior, and VS Code workspace symlinking/dependent-repo
  resolution logic.
