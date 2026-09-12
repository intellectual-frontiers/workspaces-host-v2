# Feature Specification: One-Step Installer

**Feature Branch**: `020-one-step-installer`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "Make the installation a one-step curl install.sh | sh installation directly from GitHub which auto-senses Debian and other distro families and performs all the steps from 4 to 7 so that users don't need to do multiple steps. It should be a one-step after creation of the WSL instance or VM or physical server. Whatever 'smarts' you need, put it into the install.sh script."

## Background

The Installation section's steps 4-7 (prerequisites, install Nix, enable
flakes, clone + build + activate) were four separate manual steps, each
with its own platform-specific variation (apt vs. dnf vs. pacman;
single-user vs. daemon). Feature 019's `current`/`--impure` real-identity
profiles made a single, portable set of commands possible for the first
time (no more per-arch attribute substitution). This feature collapses
those four steps into one script, run once via a single copy-pasted
command.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One command from a fresh WSL/VM/server to a working sandbox (Priority: P1)

An engineer who just created a fresh WSL Debian instance, VM, or
physical server runs one command and ends with a fully activated
profile - no separate prerequisite/Nix-install/flakes-enable/clone/build
steps to run themselves.

**Independent Test**: Run `install.sh` on a machine with only `curl`
present (nothing else pre-installed); confirm it installs prerequisites,
installs Nix, enables flakes, clones the repo, and activates the
`current` profile, ending with a working `doctor`.

**Acceptance Scenarios**:

1. **Given** a fresh Debian/Ubuntu machine, **When** `install.sh` runs,
   **Then** it detects the distro family via `/etc/os-release`, installs
   `curl`/`git` via `apt` if missing, installs Nix (single-user),
   enables flakes, clones this repo to `$WORKSPACES_HOST_REPO` (default
   `~/.workspaces-host-v2`), and builds + activates
   `$WORKSPACES_HOST_PROFILE` (default `current`) with `--impure`.
2. **Given** a RHEL/Fedora/CentOS or Arch machine, **When** `install.sh`
   runs, **Then** it uses `dnf`/`pacman` respectively for the same
   prerequisite step, with no other change.
3. **Given** macOS, **When** `install.sh` runs, **Then** it skips
   Linux-package-manager detection entirely (macOS already has
   `curl`/`git`, or the script says to install the Xcode Command Line
   Tools) and proceeds identically otherwise.
4. **Given** an unrecognized Linux distro, **When** `install.sh` runs,
   **Then** it exits with a clear message naming the detected
   `ID`/`ID_LIKE` and asking the engineer to install `curl`/`git`
   themselves, changing nothing else.
5. **Given** the script is run a second time on an already-set-up
   machine, **When** it runs, **Then** every step is idempotent (skips
   an already-installed Nix, doesn't duplicate the flakes config line,
   `git pull`s instead of re-cloning, rebuilds/reactivates) - safe to
   treat as an update mechanism too.

---

### Edge Cases

- **`curl ... | sh` was deliberately not used.** That form hands the
  script's own stdin to the shell executing it, so anything downstream
  needing real terminal input (a `sudo` password prompt, an installer
  confirmation) can't get it. The documented invocation is
  `sh -c "$(curl -fsSL .../install.sh)"` instead - downloads the whole
  script into an argument first, leaving the actual terminal stdin
  untouched for the entire run (the same pattern Homebrew's own
  installer uses).
- `$USER` is not guaranteed to be exported even when `whoami` works
  (confirmed directly in this project's own dev sandbox) - `install.sh`
  falls back to `whoami` defensively before relying on it, matching
  `pkgs/workspaces-host-update`'s existing fallback (feature 019).
- Bash-only syntax (`<(...)` process substitution) does not work under a
  strict POSIX `sh` (confirmed: `dash -n` rejected the first draft) -
  the script downloads the Nix installer to a temp file and runs it with
  `sh`, rather than using process substitution, and was re-verified
  against both `sh -n` and `dash -n`.
- A pre-existing, non-git directory at `$WORKSPACES_HOST_REPO` is treated
  as a real error (clear message, no data touched) rather than silently
  overwritten or silently ignored.
- `install.sh` is a bootstrap script that runs *before* Nix exists on the
  machine, so it is intentionally plain POSIX shell at the repo root, not
  a Nix package - it cannot depend on anything this flake provides.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `install.sh` MUST detect and handle, for the prerequisite
  (`curl`/`git`) install step: Debian/Ubuntu (`apt`), RHEL/Fedora/CentOS
  (`dnf`), Arch (`pacman`), and macOS (Xcode Command Line Tools
  guidance) - failing clearly, without side effects, for anything else.
- **FR-002**: `install.sh` MUST install Nix in single-user mode
  (`--no-daemon`) if not already present, and MUST be idempotent
  (skip if `nix` is already on `PATH`).
- **FR-003**: `install.sh` MUST enable `nix-command`/`flakes` in
  `~/.config/nix/nix.conf` idempotently (no duplicate lines on a re-run).
- **FR-004**: `install.sh` MUST clone this repo to `$WORKSPACES_HOST_REPO`
  (default `~/.workspaces-host-v2`) if absent, or `git pull --ff-only`
  it if already a clone, erroring clearly if the path exists as
  something else.
- **FR-005**: `install.sh` MUST build and activate
  `$WORKSPACES_HOST_PROFILE` (default `current`) with `--impure`.
- **FR-006**: README.md's Windows/WSL walkthrough MUST present
  `install.sh` (via `sh -c "$(curl -fsSL ...)"`) as the primary
  installation path, with the equivalent manual steps preserved in a
  clearly-labeled follow-up section for anyone who wants to see or
  control them individually.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `sh -n install.sh` and `dash -n install.sh` both accept the
  script with no syntax errors.
- **SC-002**: Run for real in this project's own dev sandbox (Nix
  already present, exercising every step except the actual Nix install):
  detects prerequisites already present, clones a fresh test repo,
  builds and activates `current` successfully.
- **SC-003**: Re-run immediately after: correctly reports the clone as
  already up to date (pulls instead of re-cloning) and does not
  duplicate the `nix.conf` flakes line.
- **SC-004**: Run against a path that exists but isn't a git repo: exits
  non-zero with a clear message, without modifying that path.
- **SC-005**: `nix flake check --all-systems` continues to pass
  (`install.sh` is not part of the flake's own evaluation).

## Assumptions

- Fetching `https://nixos.org/nix/install` directly was not reachable
  from this project's own dev sandbox (organization network policy
  blocks `nixos.org` specifically, confirmed via the sandbox's own proxy
  status endpoint) - the Nix-install step itself could not be exercised
  end-to-end here, only verified as correctly skipped (idempotent) when
  Nix is already present, and reviewed for POSIX-shell correctness. A
  real target machine (a fresh WSL/VM/server, which is exactly this
  script's intended use case) does not have this restriction.
- `install.sh` always installs Nix single-user, even on real Linux/macOS
  where a daemon-mode install is also possible - one consistent behavior
  everywhere, rather than the previously-documented distinction, in
  keeping with this feature's "smarts belong in the script, not the
  reader" goal.
