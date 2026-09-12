# Feature Specification: README Outcomes Framing & Beginner-Friendly Onboarding

**Feature Branch**: `016-readme-outcomes-and-onboarding`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "Remove historical artifacts of where the repo originated from and any focus on being a successor and only introduce the repo for its outcomes and benefits. Improve the installation instructions so that it gives concise grouped instructions for WSL using single-user mode (no JSON configuration changes) and assume that those on Windows with WSL are the target audience and then explain the same for the other distributions. Explain how to use CLI to update .gitconfig and other passwords and secrets directly using the easiest to understand approach. Fix the README to target the least experienced Windows professionals."

## Background

README.md had accumulated a lot of "how this repo came to be" framing
across many prior features - "the from-scratch successor to
strategy-coach/workspaces-host", "the original repo used X", "native port
of strategy-coach/workspaces", "this rewrite consolidates..." - useful
context while the repo was actively being built feature-by-feature
against a known original, but not useful, and actively distracting, to
someone encountering this repo fresh who just wants to know what it does
for them. Separately, the Installation section was written distro-first
(Debian as the reference platform, WSL as one of several equally-weighted
targets) and used vocabulary (Nix, flake, activation) without explanation
- a reasonable choice while this was a project bootstrapping document, a
poor one for the actual majority audience (a Windows professional using
WSL, often for the first time).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A first-time reader understands what this does for them, not where it came from (Priority: P1)

Someone with no prior context opens README.md and immediately understands
what capability they get, without needing to know or care about any
predecessor project.

**Independent Test**: Read README.md top to bottom; confirm no reference
to this repository being a rewrite, port, or successor of another
project, or to that project's own name, remains anywhere in the document.

**Acceptance Scenarios**:

1. **Given** the rewritten README, **When** searched for
   "strategy-coach", "successor", "original repo"/"original README", or
   "the previous generation of this repository", **Then** zero matches
   are found.
2. **Given** the "What you get" section (replacing the old "Why a
   rewrite" section), **When** read on its own, **Then** it communicates
   the repository's value entirely in terms of capabilities delivered,
   with no comparison to a prior system required to understand it.
3. **Given** feature-specific sections (mgit, pgpass, Java toolchain,
   compliance tooling, bulk git tooling), **When** read, **Then** each
   describes what the feature does and why, without "the original repo
   did X, so this does Y instead" framing. Attribution to genuinely
   external upstream projects a tool wraps or reimplements (e.g.
   `netspective-labs/sql-aide`'s `pgpass.ts` format, `gruntwork-io/git-xargs`)
   is retained, since that's independent, useful attribution - not part
   of this repository's own origin narrative.

---

### User Story 2 - A Windows professional with no Linux/Nix experience gets a working sandbox by following one linear set of steps (Priority: P1)

Someone on Windows, who has not used WSL, Linux, or Nix before, follows
the Installation section's Windows-first path and ends with a working,
verified setup, without needing to understand what a "flake" is beyond
one plain-language sentence, and without editing any configuration file
by hand (every file change happens via a copy-pasted command).

**Independent Test**: Follow the WSL walkthrough exactly as written,
using the single-user (`--no-daemon`) Nix install with no `/etc/wsl.conf`
edit and no systemd requirement; confirm every step is a copy-pasteable
command or a plain-language UI instruction, ending in a passing `doctor`
run.

**Acceptance Scenarios**:

1. **Given** the Windows/WSL section, **When** followed in order, **Then**
   it never asks the reader to enable `systemd` or edit `/etc/wsl.conf` -
   the single-user Nix install is used throughout, exactly as the user
   requested ("single-user mode (no JSON configuration changes)").
2. **Given** the same section, **When** read, **Then** "Nix", "flake",
   and "activating" are each given a one-sentence, jargon-free
   explanation before first use.
3. **Given** the "Other platforms" section, **When** read immediately
   after the Windows/WSL section, **Then** it's expressed as a short,
   concise delta against the Windows steps (what to skip, what to change)
   rather than a second full parallel walkthrough - satisfying "concise
   grouped instructions."

---

### User Story 3 - Updating git identity and other secrets from the CLI is a single obvious step (Priority: P1)

Someone who just saw `doctor`'s git-identity `WARN` finds, in one place,
the exact command to fix it - no need to understand Nix module syntax to
make the simplest, most common change.

**Independent Test**: Run the documented `sed` command (with placeholder
name/email) against the actual `home/git.nix` and confirm it produces the
expected, syntactically valid result; confirm the section is reachable
from a single, clearly-named heading.

**Acceptance Scenarios**:

1. **Given** README's "Updating your Git identity, and other secrets,
   from the CLI" section, **When** its `sed` command is run against
   `home/git.nix` with real values substituted, **Then** it correctly
   updates exactly the `userName`/`userEmail` lines and nothing else,
   verified against the actual current file content (not assumed from
   memory).
2. **Given** the same section, **When** read end to end, **Then** it
   covers, in increasing order of complexity: git identity (simplest),
   database passwords (`~/.pgpass`, already a plain file), and
   short-lived tokens/other secrets (the existing sops/age + direnv
   mechanism from feature 004, explained in plainer language and fewer
   words than its previous "Secrets & credential hygiene" phrasing,
   without changing what it actually does).

---

### Edge Cases

- The Roadmap table's per-phase descriptions needed the same treatment as
  prose sections - two rows (`8`, `10`) referenced "the original repo"/
  "native port of strategy-coach/workspaces" and were reworded to
  describe the outcome only; every other row already described an
  outcome and needed no change.
- Genuine third-party upstream attributions (nerd-fonts, git-xargs,
  sql-aide's pgpass.ts format, surveilr/packages, cnquery/steampipe/
  openobserve upstream projects) are a different category from this
  repository's own origin story and are intentionally kept - removing
  them would make the docs less useful, not more outcome-focused.
- This is a documentation-only change - no `home/*.nix`, `pkgs/*`, or
  `flake.nix` content changed, so no rebuild/re-activation was required
  to verify it; verification is a careful full read-through plus running
  the one command (`sed`) the new section tells readers to run, against
  the real file it targets.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: README.md MUST NOT reference this repository as a
  "rewrite", "successor", or "port" of any specific predecessor project,
  and MUST NOT name that predecessor project.
- **FR-002**: README.md's opening section MUST describe the repository
  entirely in terms of capabilities/outcomes for the reader.
- **FR-003**: The Installation section MUST present the Windows-via-WSL
  path first, as the primary/default path, using the single-user
  (`--no-daemon`) Nix install with no `/etc/wsl.conf`/systemd step in the
  main flow, and with every configuration change expressed as a
  copy-pasteable command rather than "open this file and edit it."
  Terminology (Nix, flake, activation) MUST be given a one-sentence
  plain-language explanation before first use in that section.
- **FR-004**: Instructions for Linux (VM/bare metal) and macOS MUST be
  expressed concisely as deltas against the Windows/WSL steps, not as
  fully independent parallel walkthroughs.
- **FR-005**: README.md MUST include a section explaining how to update
  git identity (`home/git.nix`) via a single CLI command, and how to
  manage database passwords (`~/.pgpass`) and other expiring secrets
  (GitHub/GitLab tokens via the existing sops/age + direnv mechanism)
  from the CLI, ordered from simplest to most involved.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Grepping README.md for `strategy-coach`, `successor`,
  `original repo`, `original README`, and `previous generation of this
  repository` returns zero matches.
- **SC-002**: The documented git-identity `sed` command, run against the
  actual `home/git.nix` in this repository, produces the exact expected
  before/after diff (verified, not assumed).
- **SC-003**: The Windows/WSL installation path contains no step that
  edits `/etc/wsl.conf` or requires enabling `systemd`.
- **SC-004**: The "Other platforms" section is materially shorter than
  the Windows/WSL section and is structured as deltas, not a repeated
  full walkthrough.

## Assumptions

- "No JSON configuration changes" is interpreted as: no manual editing of
  a settings file with a text editor, and no requirement to enable
  `systemd`/edit `/etc/wsl.conf` for the primary path - `nix.conf`'s one
  required line is still needed for flakes to work at all (there is no
  way around this with the plain upstream Nix installer), but it's
  delivered as a single copy-paste command block, never framed as
  "editing a config file."
- This is a documentation-only feature - no code, spec-kit numbering for
  other features, or package changes are affected. Feature numbering
  continues sequentially from the last merged feature (015).
