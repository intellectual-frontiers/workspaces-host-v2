# Feature Specification: Port the Original oh-my-posh Theme

**Feature Branch**: `008-port-original-theme`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "Port the original strategy-coach/workspaces-host repo's oh-my-posh theme (coach.omp.json) byte-for-byte, replacing the placeholder theme from Phase 1"

## Background

Phase 1's `themes/oh-my-posh/default.omp.json` was a minimal theme written from
scratch, since this project had no access to `strategy-coach/workspaces-host`
at the time (explicitly out of reach per this repo's own bootstrap
instructions). That constraint no longer holds: the original repo is a public
GitHub repository and readable directly. Its actual theme -
`dot_config/oh-my-posh/coach.omp.json`, wired via `oh-my-posh init fish
--config ~/.config/oh-my-posh/coach.omp.json` in `dot_config/fish/config.fish`
- is a full powerline/diamond "boxed" prompt (OS icon, path, git status on the
left; node/go/julia/python/ruby/azfunc/aws/root/execution-time/exit-status/
clock on the right, contextually shown), not the placeholder this repo shipped.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The default profile renders the original repo's actual prompt (Priority: P1)

An engineer applies this flake's `default` profile and gets the exact same
oh-my-posh styling `strategy-coach/workspaces-host` shipped - not a
lookalike, the same theme file.

**Why this priority**: The whole point of this correction. A "close enough"
re-creation would still be a regression from what this rewrite promises
(carrying over the old repo's UX, not just its concepts) for the one visual
element engineers look at in every single shell session.

**Independent Test**: Diff the original repo's `coach.omp.json` against this
repo's theme file for byte equality; activate the profile and confirm
`oh-my-posh print primary` renders correctly (no parse errors, git segment
reacts to actual repo state) using the home-manager-generated config.

**Acceptance Scenarios**:

1. **Given** `strategy-coach/workspaces-host`'s
   `dot_config/oh-my-posh/coach.omp.json`, **When** compared to this repo's
   `themes/oh-my-posh/coach.omp.json`, **Then** they are byte-identical.
2. **Given** the `default` profile is activated, **When** `oh-my-posh print
   primary` is run against the generated
   `~/.config/oh-my-posh/config.json`, **Then** it renders without error and
   is semantically identical JSON to the checked-in theme (Nix's JSON
   serializer re-encodes `\uXXXX` escapes as raw UTF-8 bytes, which is a
   text-encoding difference, not a content difference - verified by parsing
   both as JSON and comparing the resulting structures).
3. **Given** the activated profile inside a git repository with a dirty
   working tree, **When** the prompt renders, **Then** the git segment's
   background reacts (per the theme's `background_templates`) exactly as it
   does in the original repo.

---

### Edge Cases

- The theme's icons are Nerd Font private-use-area glyphs (branch icon, OS
  icon, folder icon, exit-status icon, clock icon, etc.) - same requirement
  the original repo already had. This feature does not add a Nerd Font
  dependency to the flake (matching the original repo's own approach of
  expecting the engineer's terminal to have one installed); it only carries
  the theme file over unchanged.
- The theme's right-side segments (node/go/julia/python/ruby/azfunc/aws) are
  conditional on project context (e.g. `package.json` present) - this is
  oh-my-posh's own existing behavior, unaffected by this port.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `themes/oh-my-posh/coach.omp.json` MUST be byte-identical to
  `strategy-coach/workspaces-host`'s `dot_config/oh-my-posh/coach.omp.json`.
- **FR-002**: `home/shell.nix` MUST reference this file (replacing the
  removed `default.omp.json` placeholder).
- **FR-003**: The `default` profile's generated
  `~/.config/oh-my-posh/config.json` MUST be semantically identical JSON to
  the checked-in theme file.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `themes/oh-my-posh/coach.omp.json` is byte-identical to the
  original repo's theme file (verified via `cmp`).
- **SC-002**: `nix build .#homeConfigurations.default.activationPackage`
  succeeds and a real activation's generated oh-my-posh config parses to the
  same JSON structure as the checked-in theme.
- **SC-003**: `nix flake check --all-systems` continues to pass.

## Assumptions

- The original repo's theme requiring a Nerd Font is an unchanged,
  pre-existing requirement, not something this feature needs to address
  (e.g. by bundling a Nerd Font into the flake) - out of scope here.
