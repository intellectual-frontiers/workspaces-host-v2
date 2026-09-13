---

description: "Task list for Replace fish with bash, Add fish-like Interactive Tooling, Preinstall Modern CLI Replacements"

---

# Tasks: Replace fish with bash, Add fish-like Interactive Tooling, Preinstall Modern CLI Replacements

**Input**: Design documents from `/specs/030-fish-to-bash-migration/`

## Phase 1: User Story 1 - Every layer of the repo uses bash, not fish (P1) 🎯

- [x] T001 [US1] Update `flake.nix`'s description string from
      "fish, oh-my-posh, direnv, git" to "bash, oh-my-posh, direnv, git"
- [x] T002 [US1] Rewrite `home/shell.nix`: `programs.bash` (enable,
      aliases, `initExtra`) replacing `programs.fish`; oh-my-posh's
      `enableFishIntegration` -> `enableBashIntegration`
- [x] T003 [US1] Update `oci/default.nix` and `oci/sandboxed.nix`: copy
      `.bashrc`/`.bash_profile`/`.profile` (via a `dotfile` helper
      reading `cfg.home.file.${name}.source`) instead of fish's
      `xdg.configFile` config; `Cmd`/entrypoint set to
      `bash -l`
- [x] T004 [US1] Update `oci/sandboxed-entrypoint.sh`: `set -- fish` ->
      `set -- bash -l`
- [x] T005 [US1] Update `install.sh`: `chsh` target
      `$HOME/.nix-profile/bin/bash` instead of fish's path; comments/log
      messages reworded accordingly
- [x] T006 [US1] Update `pkgs/doctor/doctor`: replace fish-on-PATH and
      fish-login-shell checks with bash equivalents (`check_cmd bash`,
      login-shell check via `getent passwd` against
      `$HOME/.nix-profile/bin/bash`)
- [x] T007 [US1] Fix the remaining fish-syntax comment in
      `pkgs/workspaces-host-update/workspaces-host-update` (fish's
      `set -gx` -> bash's `export`)
- [x] T008 [US1] Full-repo grep for `fish` after all edits; confirm
      every remaining hit is a historical/contrastive comment (README's
      "why not fish", constitution amendment note, `home/java.nix`'s
      accurate predecessor-repo mention, `home/direnv.nix`'s comment
      about home-manager's own `enableFishIntegration` option name) -
      none in active configuration

**Checkpoint**: no functional fish dependency remains anywhere in the
repo; every layer configures and launches bash

## Phase 2: User Story 2 - Credential-scoping wrapper functions work identically under bash (P1) 🎯

- [x] T009 [US2] Rewrite `home/ai-harness.nix`'s `wrapCli`: generate a
      bash function per tool (`local` predeclare each candidate env
      var, loop setting `export "$var=$(cat "$f")"` only when a
      matching secret file exists, then `command <name> "$@"`); wire
      via `programs.bash.initExtra` instead of `programs.fish.functions`
- [x] T010 [US2] Verify live, end to end: a fake secret file + a fake
      target binary, confirming the wrapper sets the env var only for
      that invocation and it does not leak into the parent shell -
      bash's `local` is function-scoped (unlike fish's block-scoped
      `set -lx`), confirmed directly rather than assumed

**Checkpoint**: Constitution Principle III's per-invocation secret
scoping guarantee holds identically under bash

## Phase 3: User Story 3 - Newbie friction reducers: fish-like interactive editing under bash (P2) 🎯

- [x] T011 [US3] Wire `blesh` (ble.sh) in `home/shell.nix` via
      `lib.mkOrder 10` (sourced with `--attach=none`, before anything
      else touches `PROMPT_COMMAND`/readline) and a trailing
      `lib.mkOrder 2000` block calling `ble-attach` last, per ble.sh's
      own documented integration pattern
- [x] T012 [US3] Enable `programs.fzf` (fuzzy history/file search) with
      `defaultCommand`/`fileWidgetCommand`/`changeDirWidgetCommand` all
      using `fd --type f/d --hidden --exclude .git`
- [x] T013 [US3] Enable `programs.zoxide` for frecency-based directory
      jumping
- [x] T014 [US3] Inspect the generated `.bashrc` to confirm load order
      (blesh source near the top, `ble-attach` as the last line); note
      in spec/README that live rendering can't be confirmed in this
      sandbox (no real TTY - `tty`/`stty -a` both fail) and needs
      confirmation on a real terminal

**Checkpoint**: bash approximates fish's signature interactive
conveniences without requiring engineers to learn fish syntax

## Phase 4: User Story 4 - Modern Rust-based CLI tool replacements are preinstalled (P2) 🎯

- [x] T015 [US4] Add `bottom`, `du-dust`, `tealdeer`, `zellij`, `blesh`
      to `home/tools.nix`, each with a comment explaining what it
      replaces; remove the now-redundant plain `fzf` package entry
      (superseded by `programs.fzf.enable`)
- [x] T016 [US4] Wire `programs.git.delta` (`enable = true`,
      `navigate`/`line-numbers`) in `home/git.nix` as the idiomatic
      home-manager git-pager integration
- [x] T017 [US4] Add `ls`/`ll` -> `eza` and `cat` -> `bat` aliases in
      `home/shell.nix`'s `programs.bash.shellAliases`; deliberately do
      **not** alias `grep`/`find`/`du`/`top` given their Rust
      replacements' incompatible flag syntax
- [x] T018 [US4] Verify each tool activates and runs (eza, bat, rg, fd,
      dust, btm, tldr, zellij) and that the two aliases resolve
      correctly

**Checkpoint**: engineers get modern CLI tooling by default, with
aliasing limited to genuinely drop-in replacements

## Phase 5: Constitution and documentation

- [x] T019 Amend `.specify/memory/constitution.md`'s Shell UX
      constraint to describe bash as the default (with the 2026-09-13
      amendment date and the tradeoff reasoning), bump `**Version**`
      1.0.0 -> 1.1.0 and `**Last Amended**` accordingly, per the
      Governance section's amendment process
- [x] T020 Update README: "What you get" bullet, the WSL walkthrough's
      shell-switch framing, the AI-harness credentials section's "fish
      wrapper function" wording, the daily-nudge section, the doctor
      coverage summary, and the manual-install steps
      (`HOME_MANAGER_BACKUP_EXT`)
- [x] T021 Add a new "Your shell" README section: why bash was chosen,
      the ble.sh/fzf/zoxide tooling and what each does, a modern-
      replacements table (with the aliasing rationale spelled out), and
      a "Why not `oh-my-posh enable autoupgrade`?" subsection

## Phase 6: Verification and fixes surfaced by real testing

- [x] T022 Real build + activation of
      `homeConfigurations.current.activationPackage` against this
      session's own sandbox account
- [x] T023 Fix the activation failure this surfaced: a fresh account's
      pre-existing non-symlink `.bashrc`/`.profile` skeleton files
      blocked activation ("Existing file ... is in the way"). Set
      `export HOME_MANAGER_BACKUP_EXT="pre-workspaces-host-backup"`
      before `./result/activate` in `install.sh`, and document the same
      in README's manual-steps section - the underlying mechanism
      behind `home-manager switch -b`, applied here since `install.sh`
      talks to the lower-level activation script directly
- [x] T024 Re-run activation with the fix; confirm success and that old
      dotfiles were moved aside with the backup extension
- [x] T025 Run `doctor` against the activated profile; confirm every
      check passes
- [x] T026 Build `.#oci-image` for real; confirm success
- [x] T027 Build `.#oci-image-sandboxed` for real; confirm success
- [x] T028 Run `nix flake check --all-systems`; confirm it passes
- [x] T029 Final full-repo grep sweep for stray `fish` references after
      all edits are in place
