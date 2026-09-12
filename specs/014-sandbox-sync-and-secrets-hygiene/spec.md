# Feature Specification: Sandbox Sync & Secrets Hygiene

**Feature Branch**: `014-sandbox-sync-and-secrets-hygiene`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "Give standard guidance in README on how to setup Git and other dev secrets properly so devs don't mistakenly put secrets into repos, and how to use short-lived GitHub/GitLab/etc tokens so CLI tools read secrets only from env. Also add a section on how devs keep their sandboxes in sync with workspaces-host-v2 so new features are automatically incorporated, and how to manage secret/token rotation."

## Background

Two related gaps surfaced once real features started landing on `main`
regularly: (1) nothing told an already-provisioned engineer how to pick up
those new features on their own machine, and (2) `home/secrets.nix`
(feature 004) built a real sops/age + direnv secrets mechanism, but
nothing documented how to actually use it for the everyday case of "a
short-lived GitHub/GitLab token a CLI tool needs" - so an engineer would
reasonably default to a long-lived token pasted into `~/.gitconfig` or a
shell rc file instead, exactly the habit this repo's own tooling exists to
avoid.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - An engineer notices they're behind and updates in one command (Priority: P1)

An engineer who provisioned this flake weeks ago gets a passive, once-a-day
nudge when `main` has moved, and a single command to actually pick up the
change - never an automatic, unattended `home-manager switch`.

**Independent Test**: Point `$WORKSPACES_HOST_REPO` at a local clone that's
behind a local "origin"; open a new interactive shell and confirm the nudge
prints once; open a second shell the same day and confirm it's silent; run
`workspaces-host-update` and confirm it pulls and re-activates.

**Acceptance Scenarios**:

1. **Given** `$WORKSPACES_HOST_REPO` is N commits behind its `origin/main`,
   **When** a new interactive shell starts, **Then** it prints an
   informational nudge naming N and the update command, without blocking
   shell startup (the check runs in the background).
2. **Given** the nudge already printed once today, **When** another shell
   starts the same day, **Then** it does not print again.
3. **Given** `$WORKSPACES_HOST_REPO` is unset, not a git repo, or
   unreachable (offline), **When** a new shell starts, **Then** nothing
   errors and no nudge prints.
4. **Given** any state, **When** `workspaces-host-update` runs, **Then**
   it `git pull --ff-only`s `$WORKSPACES_HOST_REPO` and runs
   `home-manager switch --flake $WORKSPACES_HOST_REPO#$WORKSPACES_HOST_PROFILE`.

---

### User Story 2 - Short-lived tokens via env, never in a config file (Priority: P1)

An engineer needing a CLI tool to authenticate against GitHub/GitLab uses
a short-expiry token that lives only as an environment variable scoped to
the project directory that needs it, sourced from this repo's existing
sops/age + direnv stack - never pasted into `~/.gitconfig`, a shell rc
file, or committed to a repo.

**Independent Test**: Follow the README's documented steps end-to-end
(encrypt a token, declare it via `workspacesHost.secrets`, reference it
from a project's `.envrc`) and confirm the token is present as an env var
only inside that directory.

**Acceptance Scenarios**:

1. **Given** a token encrypted with `sops`/`age` and declared via
   `workspacesHost.secrets`, **When** `home-manager switch` runs, **Then**
   it's decrypted to `~/.local/state/workspaces-host/secrets/<path>`
   (mode 600, never in `/nix/store`) - this is feature 004's existing,
   unchanged behavior, just now documented for this specific use case.
2. **Given** a project's `.envrc` exports that decrypted value into
   `$GITHUB_TOKEN` (or similar), **When** the engineer `cd`s into that
   project, **Then** the variable is set; **When** they `cd` out, **Then**
   direnv unloads it.
3. **Given** a token expires or needs rotating, **When** the engineer
   re-encrypts the new value to the same `sopsFile` and re-activates,
   **Then** the decrypted file is overwritten in place and every `.envrc`
   referencing it picks up the new value on its next direnv reload - no
   code change.

---

### Edge Cases

- The daily nudge must never block or slow down shell startup, even with
  no network - the git fetch runs backgrounded and its failure is
  swallowed (`or exit 0`).
- `workspaces-host-update` must fail with a clear, actionable message
  (not a raw git/Nix error) when `$WORKSPACES_HOST_REPO` doesn't exist as
  a git repo yet.
- This feature does not change `home/secrets.nix`'s actual mechanism
  (already correct since feature 004) - it only documents an existing
  capability for a new, common use case, plus adds a small amount of new
  glue (the update command and nudge) for the sync half.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every profile MUST set `WORKSPACES_HOST_REPO` (default
  `~/.workspaces-host-v2`) via `home.sessionVariables`.
- **FR-002**: A new `workspaces-host-update` package MUST `git pull
  --ff-only` `$WORKSPACES_HOST_REPO` and then run `home-manager switch
  --flake $WORKSPACES_HOST_REPO#${WORKSPACES_HOST_PROFILE:-default}`,
  failing with a clear message if the repo path isn't a git clone.
- **FR-003**: Every profile's fish `interactiveShellInit` MUST check, at
  most once per calendar day (tracked via a stamp file under
  `$XDG_STATE_HOME/workspaces-host/`), in the background, whether
  `$WORKSPACES_HOST_REPO`'s `origin/main` has moved, and print an
  informational nudge naming the commit count and the update command if
  so - never running the update itself.
- **FR-004**: `pkgs/doctor/doctor` MUST report whether
  `$WORKSPACES_HOST_REPO` is set and is a real git clone.
- **FR-005**: `gitleaks` MUST be installed by every profile
  (`home/tools.nix`).
- **FR-006**: README.md MUST document: the manual sync steps, the
  `workspaces-host-update` command and its two environment variables, the
  nudge's behavior, general git-secrets hygiene (`.gitignore`, reviewing
  staged diffs, `gitleaks detect`), and the concrete
  sops/age-encrypt-then-direnv-export workflow for a short-lived
  GitHub/GitLab token, including how rotation works.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix build .#homeConfigurations.default.activationPackage`
  succeeds with all of the above included.
- **SC-002**: Against a real local git remote that's ahead of a clone,
  a new interactive shell prints the nudge exactly once per day, and
  `workspaces-host-update` correctly fast-forwards that clone.
- **SC-003**: `fish -n` (syntax check) passes against the generated
  `config.fish`, and the nudge logic was exercised in a real interactive
  fish shell (not just syntax-checked) to catch runtime-only bugs.
- **SC-004**: `nix flake check --all-systems` continues to pass.

## Assumptions

- `~/.workspaces-host-v2` becomes this project's own documented clone-path
  convention going forward (README's clone step now says so explicitly);
  engineers who already cloned elsewhere override
  `home.sessionVariables.WORKSPACES_HOST_REPO` rather than being forced to
  move their clone.
- The nudge is intentionally informational-only, never applying the
  update itself - consistent with this project's general stance that
  anything that can restructure a profile happens via an explicit human
  command, never unattended.
