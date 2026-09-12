---

description: "Task list for Doctor Hardening for Credentials & Beginner Pitfalls"

---

# Tasks: Doctor Hardening for Credentials & Beginner Pitfalls

**Input**: Design documents from `/specs/021-doctor-hardening/`

## Phase 1: User Story 1 - GitHub/GitLab credentials actually work (P1) 🎯

- [x] T001 [US1] Confirm `gh`/`glab` exist in this flake's pinned
      nixpkgs; add both to `home/tools.nix`
- [x] T002 [US1] Add a "GitHub/GitLab authentication" section to
      `pkgs/doctor/doctor`: `gh auth status`/`glab auth status`, not
      just PATH presence
- [x] T003 [US1] Verify: `nix build
      .#homeConfigurations.current.activationPackage --impure` succeeds;
      real activation's `doctor` correctly reports both as
      un-authenticated in this sandbox's actual state

**Checkpoint**: doctor tells you definitively whether GitHub/GitLab
credentials actually work

## Phase 2: User Story 2 - Common first-time Linux/WSL mistakes (P1) 🎯

- [x] T004 [US2] Discover and fix a real gap found while writing the SSH
      check: this repo provisioned no SSH client at all - add `openssh`
      to `home/tools.nix`
- [x] T005 [US2] Add SSH key existence + permissions check (`~/.ssh`
      mode, each private key's mode, warn if none exist)
- [x] T006 [US2] Add WSL `/mnt` working-directory check
      (`/proc/version` mentions "microsoft" + `$HOME` under `/mnt/*`)
- [x] T007 [US2] Add disk-space check (guarded numeric parsing of `df`
      output, suggests `nix-collect-garbage -d`)
- [x] T008 [US2] Add locale-misconfiguration check (`locale(1)` "cannot
      set" detection)
- [x] T009 [US2] Add `~/.netrc` existence + permissions check
      (stronger warning if not mode 600)
- [x] T010 [US2] Add `umask 000` check
- [x] T011 [US2] Add Docker group-membership check (skipped gracefully
      if `docker` isn't installed or already root)
- [x] T012 [US2] Verify each check against both states for real: a
      wrong-permission SSH key (generated with `ssh-keygen`) warns, then
      passes after `chmod 600`; `umask 000` warns; a wrong-permission
      `.netrc` produces the stronger warning

**Checkpoint**: doctor catches the classic first-time Linux/WSL mistakes,
not just tool presence

## Phase 3: Polish

- [x] T013 Update README's Health check section to name the expanded
      coverage
- [x] T014 Run `nix flake check --all-systems`, confirm it passes
