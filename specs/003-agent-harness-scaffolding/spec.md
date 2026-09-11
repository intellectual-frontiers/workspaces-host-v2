# Feature Specification: Agent-Harness Scaffolding

**Feature Branch**: `003-agent-harness-scaffolding`

**Created**: 2026-09-11

**Status**: Draft

**Input**: User description: "Agent-harness scaffolding: .claude conventions, AGENTS.md template, MCP server registry convention, skills directory convention, session-start hook, and specify/backlog-md as flake-packaged defaults"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - specify and backlog-md are available without a manual install step (Priority: P1)

An engineer applies this flake's home-manager profile and gets `specify`
(GitHub Spec Kit's CLI) and `backlog` (Backlog.md) on `PATH` immediately -
no `uv tool install`, no `npm install -g`, nothing outside the flake.

**Why this priority**: The roadmap explicitly calls these out as "first-class,
not a roadmap TODO like in the old repo" - if they still require a manual
install step, this feature hasn't actually changed anything.

**Independent Test**: After `home-manager switch --flake .#default`, run
`specify --help` and `backlog --version` and confirm both resolve under
the Nix store and run successfully.

**Acceptance Scenarios**:

1. **Given** a clean profile activation, **When** the engineer runs
   `specify check`, **Then** it runs successfully and reports which
   coding-agent CLIs are detected.
2. **Given** a clean profile activation, **When** the engineer runs
   `backlog --help`, **Then** it prints Backlog.md's command list.

---

### User Story 2 - One command scaffolds the agent-harness convention into any project (Priority: P1)

An engineer (or an agent) runs `scaffold-agent-harness` inside any project
directory and gets `AGENTS.md`, `.mcp.json`, `.claude/settings.json`,
`.claude/hooks/session-start.sh`, and `.claude/skills/README.md` - the
convention this repo defines for how an AI coding agent should find its
bearings in a project - without hand-copying files from this repo.

**Why this priority**: This is the actual "scaffolding" the phase name
promises; specify/backlog-md (User Story 1) are necessary but adjacent
tools, not the scaffolding itself.

**Independent Test**: In an empty scratch directory, run
`scaffold-agent-harness`, then verify all five files exist with the
expected content. Run it again and confirm nothing already present is
overwritten.

**Acceptance Scenarios**:

1. **Given** an empty directory, **When** `scaffold-agent-harness` is run
   with no arguments, **Then** all five convention files are created and
   each creation is reported (`created: <path>`).
2. **Given** a directory where `AGENTS.md` already exists with different
   content, **When** `scaffold-agent-harness` is run, **Then** `AGENTS.md`
   is left untouched and reported as `skipped (exists): AGENTS.md`, while
   any missing files are still created.
3. **Given** `scaffold-agent-harness DIR` with an explicit target,
   **When** run, **Then** files land under `DIR` rather than the current
   directory.

---

### User Story 3 - The skills directory convention is documented and consistent with Claude Code's own resolution (Priority: P2)

An engineer reads `.claude/skills/README.md` (from the scaffold) and
understands where project-local vs. personal/global skills belong,
without needing to read Claude Code's own docs first.

**Why this priority**: A convention nobody can find isn't a convention -
this is the "documentation" leg of an otherwise code-only feature, ranked
below the two functional deliverables above.

**Independent Test**: Read the generated `.claude/skills/README.md` and
confirm it correctly states that project-local `.claude/skills/<name>/`
takes precedence over `~/.claude/skills/<name>/` for the same skill name
(matching Claude Code's actual, documented resolution order).

**Acceptance Scenarios**:

1. **Given** the scaffold has been applied, **When** the engineer opens
   `.claude/skills/README.md`, **Then** it states the project-vs-global
   precedence rule and mentions that `specify init` populates
   `speckit-*` skills into this same directory.

---

### Edge Cases

- What happens if `scaffold-agent-harness` is run outside a writable
  directory? It should fail loudly (non-zero exit, clear error) rather
  than silently doing nothing - standard `cp`/`mkdir` failure behavior,
  not special-cased.
- What happens to `.claude/settings.json` if a project already has one
  with unrelated content (e.g. permissions, other hooks)? It is left
  untouched (per FR-003's non-destructive rule) - the engineer merges the
  `SessionStart` hook in by hand. This feature does not attempt a JSON
  merge.
- Why isn't `~/.claude/settings.json` (the user's own global settings)
  managed directly by home-manager? Because Claude Code itself can write
  to that file during normal use (e.g. interactive permission prompts,
  `/config`), and a home-manager-managed file is a read-only symlink into
  the Nix store - making it declarative would silently break those
  writes. The convention this feature ships instead operates at the
  project level (`.claude/settings.json`, meant to be committed and
  edited normally), which doesn't have that conflict.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The flake MUST package `specify-cli` (GitHub Spec Kit) as
  `packages.<system>.specify-cli` and include it in the default
  home-manager profile's `home.packages`.
- **FR-002**: The flake MUST package `backlog-md` (Backlog.md) as
  `packages.<system>.backlog-md` and include it in the default
  home-manager profile's `home.packages`.
- **FR-003**: The flake MUST provide a `scaffold-agent-harness` command
  (packaged as `packages.<system>.scaffold-agent-harness`, included in
  `home.packages`) that copies a fixed set of template files
  (`AGENTS.md`, `.mcp.json`, `.claude/settings.json`,
  `.claude/hooks/session-start.sh`, `.claude/skills/README.md`) into a
  target directory (default: cwd), never overwriting a file that already
  exists there.
- **FR-004**: The template's `.claude/settings.json` MUST wire a
  `SessionStart` hook to `.claude/hooks/session-start.sh`, and that script
  MUST report whether `nix` is on `PATH`, whether a `flake.nix` is present
  in the project, and whether that flake's lock file resolves.
- **FR-005**: The template's `.mcp.json` MUST use Claude Code's own
  documented project-level MCP server format (`{"mcpServers": {...}}`) -
  this feature does not invent a separate registry format.
- **FR-006**: The template's `AGENTS.md` MUST describe: that the project
  is provisioned by this flake (so packages belong in Nix, not
  `apt`/`brew`), that secrets are never ambient, and where to find
  build/test/lint commands and this project's skills.
- **FR-007**: `scaffold-agent-harness`'s template content MUST be sourced
  from `templates/agent-harness/` in this repository (not duplicated
  inline in the script), so the template can be read, reviewed, and
  updated as plain files.

### Key Entities

- **Agent-harness template**: `templates/agent-harness/`, the fixed set
  of files `scaffold-agent-harness` copies into a target project.
- **`scaffold-agent-harness`**: the flake-packaged command that applies
  the template non-destructively.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After `home-manager switch --flake .#default`, `specify`
  and `backlog` both resolve on `PATH` and run their `--help`/`check`
  commands successfully.
- **SC-002**: `scaffold-agent-harness` run twice against the same
  directory creates all five files on the first run and skips all five
  (reporting each) on the second, with no error either time.
- **SC-003**: `nix flake check --all-systems` continues to pass for all
  four target systems with the three new packages added.

## Assumptions

- The MCP servers listed in the template `.mcp.json`
  (`@modelcontextprotocol/server-filesystem`, `mcp-server-git`) are
  illustrative starting points, not a requirement that every project use
  exactly these - engineers edit `.mcp.json` per-project as normal.
- `~/.claude/skills/` (the personal/global skills directory) is
  documented as a convention in this feature's README text, but this
  feature does not create or manage that directory itself - see this
  spec's Edge Cases for why global `.claude/` state is intentionally left
  to the engineer rather than home-manager.
- specify-cli is pinned to a specific upstream commit (not a tagged
  release) because that commit is the one already verified working in
  this repository's own Phase 0 bootstrap; bumping it is a routine
  version-bump PR, not a design change.
