# Feature Specification: Simplify Credentials Onboarding

**Feature Branch**: `024-simplify-credentials-onboarding`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "I think the secrets setup and encryption
is too complicated; just like we created a simple one line installer,
let's think about how to ask users for API keys, github tokens, etc. to
setup ~/.gitconfig and other values in one file that is edited by the
user in a safe location then the `workspaces-host-update` command does
all the work and checks everything is OK."

## Background

Before this feature, setting up a single credential required: generating
an age key, running `sops --encrypt` by hand for each secret, and
hand-writing a Nix `workspacesHost.secrets.<name> = { sopsFile = ...;
path = ...; };` stanza in `~/.config/workspaces-host/local.nix` - real
friction for exactly the "young or inexperienced" engineers this repo
is meant to be approachable for, and a mismatch with how simple this
repo made the base install (`install.sh`, feature 020).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One file, one command (Priority: P1)

An engineer wants to set their git identity and give an AI CLI an API
key, without learning Nix syntax or an encryption tool first.

**Independent Test**: Run `workspaces-host-update` with no credentials
file yet; confirm it creates one from a template and stops, explaining
what to do. Fill in a few values, run it again; confirm git identity and
credentials take effect and `doctor` confirms it at the end of the same
command.

**Acceptance Scenarios**:

1. **Given** no `~/.config/workspaces-host/credentials` file exists,
   **When** `workspaces-host-update` runs, **Then** it creates the file
   from `credentials.example` at mode 600, prints instructions, and
   exits without switching.
2. **Given** a filled-in credentials file, **When**
   `workspaces-host-update` runs, **Then** it applies the git identity,
   writes each other value into the per-command-scoped secrets
   directory, runs `home-manager switch`, and finishes by running
   `doctor`.
3. **Given** the credentials file's permissions were loosened by
   something else, **When** `workspaces-host-update` runs, **Then** it
   resets them to 600 without being asked.

---

### User Story 2 - A credential never becomes shell-wide (Priority: P1)

The same Constitution Principle III constraint that shaped feature 023
still applies: simpler onboarding must not reintroduce ambient secrets.

**Independent Test**: Configure `GITHUB_TOKEN` via the credentials file;
confirm `echo $GITHUB_TOKEN` in an ordinary shell is empty, while `gh
auth status` (run through its wrapper) and `doctor`'s GitHub check both
correctly see it.

**Acceptance Scenarios**:

1. **Given** `GITHUB_TOKEN` set via the credentials file, **When** a new
   interactive shell opens, **Then** `$GITHUB_TOKEN` is unset in that
   shell.
2. **Given** the same setup, **When** the engineer runs `gh` (or
   `doctor` checks GitHub auth), **Then** the token is used for that one
   call/check only.

---

### User Story 3 - Git identity applies without a rebuild waiting on Nix syntax (Priority: P2)

**Acceptance Scenarios**:

1. **Given** `GIT_NAME`/`GIT_EMAIL` set in the credentials file, **When**
   `workspaces-host-update` runs, **Then** `git config --get user.name`/
   `user.email` reflect the new values, via git's own `[include]`
   mechanism (`home/git.nix`), not a Nix-evaluated value.
2. **Given** both are blank, **When** `workspaces-host-update` runs,
   **Then** the placeholder identity from `home/git.nix` still applies
   (git silently ignores an `[include] path` that doesn't exist).

---

### Edge Cases

- The credentials file is parsed as plain `KEY=value` text, never
  `source`d as shell - a value containing a backtick or `$(...)` must
  never be executed. Verified with a deliberately adversarial test
  value.
- A line that isn't a bare `KEY=value` (a typo, a stray colon, a key
  with spaces) is silently skipped rather than erroring the whole run -
  a beginner's mistake in this file must not break their sandbox.
- Surrounding `"`/`'` quotes around a value are stripped, since many
  people instinctively quote a value containing spaces (a name).
- The existing sops-based `workspacesHost.secrets` mechanism
  (`home/secrets.nix`) is unchanged and still available as an opt-in
  "advanced" path for anyone who wants field-level encryption at rest -
  it writes into the same `secrets/env/<NAME>` directory the new plain
  mechanism does, so the two compose without conflict.
- `gh`/`glab` now get the same per-invocation credential-wrapper
  treatment as the AI harness CLIs (`home/ai-harness.nix`), so
  `GITHUB_TOKEN`/`GITLAB_TOKEN` from the credentials file work with them
  too, and `doctor`'s GitHub/GitLab auth check retries with the token
  scoped to just that one check when plain `gh auth status`/`glab auth
  status` fails.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A tracked `credentials.example` template MUST exist at the
  repo root, documenting every recognized key.
- **FR-002**: `workspaces-host-update` MUST create
  `~/.config/workspaces-host/credentials` from that template (mode 600)
  on first run if it doesn't exist, and stop without switching.
- **FR-003**: `workspaces-host-update` MUST parse an existing
  credentials file as plain `KEY=value` (never sourced as shell),
  writing `GIT_NAME`/`GIT_EMAIL` into a git-config-format file
  `home/git.nix` includes, and every other recognized value into
  `$XDG_STATE_HOME/workspaces-host/secrets/env/<KEY>` at mode 600.
- **FR-004**: `workspaces-host-update` MUST re-assert mode 600 on the
  credentials file every run, then run `home-manager switch`, then run
  `doctor`.
- **FR-005**: `home/ai-harness.nix`'s per-invocation credential-wrapper
  mechanism MUST extend to `gh` and `glab` in addition to the four AI
  CLIs.
- **FR-006**: `pkgs/doctor/doctor` MUST report the credentials file's
  existence and permissions, and MUST treat a working `GITHUB_TOKEN`/
  `GITLAB_TOKEN` (retried with the token scoped to that one check) as
  authenticated even when plain `gh auth status`/`glab auth status`
  fails.
- **FR-007**: The existing sops-based `workspacesHost.secrets` mechanism
  MUST remain available and documented as an advanced, opt-in path.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix build .#homeConfigurations.current.activationPackage
  --impure` succeeds with every changed module.
- **SC-002**: Real, not just inspected: a fresh-HOME test proves the
  first-run template bootstrap, quote-stripped and typo-tolerant
  parsing, git-identity generation, and mode-600 auto-fix all work as
  specified.
- **SC-003**: A real encrypt-free credentials cycle (fake GitHub token
  and AI API key) proves the ambient shell never sees the value while
  the wrapped CLI/doctor check does.
- **SC-004**: `nix flake check --all-systems` continues to pass.

## Assumptions

- Most engineers using this repo do not need field-level encryption at
  rest for a personal, single-user sandbox; ordinary file permissions
  (the same trust model as `~/.ssh` or `~/.aws/credentials`) are an
  accepted, industry-standard default here, with sops available for
  anyone who wants more.
- `~/.pgpass` is out of scope for this consolidation - it's already a
  single, directly-edited flat file in the format PostgreSQL itself
  requires, and already matches the "simple file" goal this feature is
  bringing to everything else.
