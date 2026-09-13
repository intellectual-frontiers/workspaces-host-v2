# Feature Specification: Replace fish with bash, Add fish-like Interactive Tooling, Preinstall Modern CLI Replacements

**Feature Branch**: `030-fish-to-bash-migration`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User decision after reviewing feature 029's fish-vs-bash
tradeoff writeup: "since we're letting AI manage everything let's stay
with `bash` and oh-my-posh and remove `fish` and fix everything from
there. I want zero friction so make suggestions for anything else that
might cause newbies friction. if there are any other cool utilities for
`bash` that allow easier command line editing manipulation to allow
`bash` to operate similarly to `fish` for interactive usage, proceed
with that too. also see modern rust-based utilities like `exa` and
others and preinstall those to improve the lives of those that live in
the command line."

## Background

Feature 029 fixed fish not actually becoming the login shell, but
explicitly left the fish-vs-bash choice to the user, recommending fish
for its native interactive conveniences (autosuggestions, syntax
highlighting) despite the maintenance cost of engineers needing to
translate copy-pasted bash snippets. The user has now made that call
explicitly: since AI coding agents (not engineers hand-typing fish
syntax) manage most of this environment day to day, the value of "one
identical shell for everyone" is outweighed by "nothing copy-pasted
from anywhere ever needs translating." This feature removes fish
everywhere it appeared, replaces its native interactive niceties with
bash-compatible tooling that approximates them, and preinstalls modern
Rust-based CLI replacements the user asked about by name (`exa`, which
is deprecated upstream in favor of its actively maintained fork `eza`).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Every layer of the repo uses bash, not fish (Priority: P1)

**Independent Test**: Grep the repo for `fish` outside of historical/
contrastive comments (README's "why not fish" explanation, the
constitution's amendment note, `home/java.nix`'s accurate mention of
the *predecessor* repo); confirm none remain in active configuration.
Build and activate a profile; confirm `~/.bashrc`/`~/.bash_profile`
exist and are home-manager-managed, and no fish config is generated.

**Acceptance Scenarios**:

1. **Given** a fresh activation, **When** inspecting `$HOME`, **Then**
   `.bashrc`, `.bash_profile`, and `.profile` are symlinks into the Nix
   store, and no `~/.config/fish/` exists.
2. **Given** the OCI images (`oci/default.nix`, `oci/sandboxed.nix`),
   **When** built, **Then** their entrypoint is bash (`bash -l`), and
   the copied-in dotfiles are the three bash ones, not fish's config
   file.
3. **Given** `install.sh`, **When** it sets the login shell, **Then**
   it targets `$HOME/.nix-profile/bin/bash` (this flake's pinned bash,
   not the OS's own `/bin/bash`), with the same best-effort/warn-not-
   abort behavior feature 029 established for fish.
4. **Given** `pkgs/doctor/doctor`, **When** run, **Then** every fish-
   specific check (fish-on-PATH, fish login shell) is replaced by its
   bash equivalent.

---

### User Story 2 - Credential-scoping wrapper functions work identically under bash (Priority: P1)

**Independent Test**: Set a fake secret file and a fake target binary;
invoke the generated wrapper function; confirm the secret env var is
set only for that invocation's child process, not leaked into the
wrapping shell or sibling invocations - the same guarantee feature 023
verified for fish, now verified for bash's different scoping rules
(`local` is function-scoped in bash, not block-scoped like fish's
`set -lx`).

**Acceptance Scenarios**:

1. **Given** `home/ai-harness.nix`'s `wrapCli`-generated bash function,
   **When** a matching secret file exists, **Then** the wrapped command
   sees the env var, and it does not persist in the parent shell after
   the function returns.
2. **Given** no matching secret file, **When** the wrapped command
   runs, **Then** it runs without that env var, with no error.

---

### User Story 3 - Newbie friction reducers: fish-like interactive editing under bash (Priority: P2)

**Independent Test**: Activate a profile; inspect the generated
`.bashrc`; confirm ble.sh, fzf, and zoxide are wired in the correct
load order (ble.sh sourced with `--attach=none` before anything else
touches `PROMPT_COMMAND`/readline; `ble-attach` deferred to the very
last line).

**Acceptance Scenarios**:

1. **Given** an interactive bash session on a real terminal, **When**
   typing a command, **Then** ble.sh provides fish-like syntax
   highlighting and history-based autosuggestions.
2. **Given** a directory search, **When** using `fzf`'s Ctrl-R/Ctrl-T
   bindings, **Then** results are fuzzy-matched using `fd` under the
   hood (respecting `.gitignore`, hidden files included, `.git`
   excluded).
3. **Given** a previously-visited directory, **When** using `zoxide`
   (`z <partial-name>`), **Then** it jumps there without a full path.

---

### User Story 4 - Modern Rust-based CLI tool replacements are preinstalled (Priority: P2)

**Independent Test**: Activate a profile; confirm each tool in the
table below (README's "Your shell" section) is on `PATH` and, where
aliased, that the alias resolves correctly.

**Acceptance Scenarios**:

1. **Given** a fresh activation, **When** running `ls`/`ll`, **Then**
   `eza` runs instead of coreutils `ls` (icons, git status column).
2. **Given** a fresh activation, **When** running `cat somefile`,
   **Then** `bat` runs instead of coreutils `cat` (syntax highlighting).
3. **Given** a fresh activation, **When** running `git diff`, **Then**
   `delta` renders the diff (already wired via feature work in this
   session, confirmed still intact here).
4. **Given** a fresh activation, **When** running `rg`, `fd`, `dust`,
   `btm`, `tldr`, or `zellij` directly (deliberately *not* aliased over
   their traditional counterparts - see rationale below), **Then** each
   runs successfully.

---

### Edge Cases

- A brand-new Debian/WSL account already has non-symlink `.bashrc`/
  `.profile` skeleton files (`/etc/skel/`); home-manager safely refuses
  to overwrite them by default. `install.sh` sets
  `HOME_MANAGER_BACKUP_EXT` before activating so these are moved aside
  (`*.pre-workspaces-host-backup`) rather than failing the whole
  install - discovered via a real failed activation attempt on this
  session's own sandbox, not hypothetical.
- `grep`, `find`, `du`, and `top`/`htop` are deliberately **not**
  aliased to their Rust replacements (`rg`, `fd`, `dust`, `btm`)
  despite being preinstalled: their flag syntax differs enough from the
  originals that aliasing them over muscle memory or copy-pasted
  snippets (this repo's stated bash-was-chosen-for reason) would
  reintroduce exactly the friction switching to bash was meant to
  avoid. Only `ls`→`eza` and `cat`→`bat` are aliased, since both are
  drop-in compatible for common usage.
- `exa` (the tool the user named) is unmaintained upstream; `eza` is
  its actively-maintained fork and is what's actually packaged in
  nixpkgs going forward - `eza` is used, not `exa`, and this
  substitution is called out explicitly rather than silently.
- ble.sh's live interactive rendering (autosuggestions actually
  appearing, syntax highlighting colors) cannot be verified inside this
  session's own remote sandbox, which has no real TTY at all (`tty`
  reports "not a tty"; `stty -a` reports "Inappropriate ioctl for
  device"). The Nix-level wiring (correct store path, correct
  `mkOrder`-based load order in the generated `.bashrc`) is verified by
  inspection; live rendering needs confirmation on a real terminal,
  called out as a caveat rather than silently assumed to work.
- `oh-my-posh enable autoupgrade` remains rejected (per feature 029,
  unchanged by this migration): the binary lives in the read-only Nix
  store, so self-upgrading would fight Nix's model.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every Nix module, OCI image definition, and shell script
  in this repository MUST configure and reference bash, not fish, as
  the default interactive shell.
- **FR-002**: `home/ai-harness.nix`'s credential-scoping wrapper
  mechanism MUST be reimplemented in bash, preserving the exact
  per-invocation scoping guarantee (Constitution Principle III) fish's
  version had.
- **FR-003**: `home/shell.nix` MUST wire ble.sh (syntax highlighting +
  autosuggestions), `fzf` (fuzzy history/file search, backed by `fd`),
  and `zoxide` (frecency-based directory jumping) as bash-native
  approximations of fish's built-in interactive conveniences.
- **FR-004**: `home/tools.nix` MUST preinstall modern Rust-based CLI
  tool replacements: `eza`, `bat`, `ripgrep`, `fd`, `du-dust`,
  `bottom`, `tealdeer`, `zellij`, `blesh`, and `git-delta` (via
  `programs.git.delta`), aliasing only the drop-in-compatible pair
  (`ls`→`eza`, `cat`→`bat`) and leaving flag-incompatible replacements
  (`rg`, `fd`, `dust`, `btm`) as separate commands.
- **FR-005**: `install.sh` MUST set `HOME_MANAGER_BACKUP_EXT` before
  activation, so a fresh account's pre-existing non-symlink dotfiles
  are backed up rather than blocking the install.
- **FR-006**: `pkgs/doctor/doctor` MUST check bash-equivalents of every
  removed fish-specific check (login shell, wrapper functions), plus
  new checks for ble.sh wiring and git-delta wiring.
- **FR-007**: `.specify/memory/constitution.md`'s Shell UX constraint
  MUST be amended (with version bump and reasoning recorded) to
  describe bash as the default, per the Governance section's
  amendment process.
- **FR-008**: README MUST document the new default shell, the added
  fish-like tooling and why each was chosen, the modern CLI tool table
  with the aliasing rationale, and the `HOME_MANAGER_BACKUP_EXT` fix.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A full-repo grep for `fish` outside historical/
  contrastive comments returns zero matches in active configuration.
- **SC-002**: A real `nix build
  .#homeConfigurations.current.activationPackage --impure` +
  `HOME_MANAGER_BACKUP_EXT`-guarded activation succeeds end to end on
  this session's own sandbox, starting from its pre-existing non-symlink
  dotfiles.
- **SC-003**: `doctor` passes every check on the freshly-activated
  profile.
- **SC-004**: The credential-wrapper bash functions are verified live,
  end to end, with a fake secret and fake binary, confirming identical
  scoping behavior to the fish version.
- **SC-005**: Both `.#oci-image` and `.#oci-image-sandboxed` build
  successfully with the bash-based dotfile-copying logic.
- **SC-006**: `nix flake check --all-systems` passes.
- **SC-007**: ble.sh's Nix-level wiring (store path, load order in the
  generated `.bashrc`) is confirmed by inspection, with the live-
  rendering limitation of this sandbox explicitly documented rather
  than silently assumed to work.

## Assumptions

- The credential-scoping wrapper's bash reimplementation relies on
  `local` being function-scoped (not block-scoped) in bash, verified
  directly against this session's own bash rather than assumed from
  general knowledge, since fish's own equivalent scoping bug (feature
  023) was only caught by real testing, not by trusting documentation.
- "Zero friction for newbies" is interpreted as: no new command syntax
  to memorize beyond what's optional (ble.sh/fzf/zoxide all activate
  passively or via familiar keybindings; the two aliases are drop-in),
  and no step in `install.sh` that silently fails instead of either
  succeeding or clearly warning.
