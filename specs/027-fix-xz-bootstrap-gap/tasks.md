---

description: "Task list for Fix the xz Bootstrap Gap on Fresh Linux Installs"

---

# Tasks: Fix the xz Bootstrap Gap on Fresh Linux Installs

**Input**: Design documents from `/specs/027-fix-xz-bootstrap-gap/`

## Phase 1: User Story 1 - install.sh installs everything the Nix installer needs (P1) 🎯

- [x] T001 [US1] Extend `install_prereqs_linux`'s short-circuit check
      and each distro branch to also detect/install `xz` (`xz-utils` on
      Debian/Ubuntu, `xz` on RHEL/Fedora/CentOS and Arch)
- [x] T002 [US1] Extend the macOS (`Darwin`) branch to check for `xz`
      the same way it already checks for `curl`/`git`
- [x] T003 [US1] Verify `sh -n`/`dash -n` syntax validity
- [x] T004 [US1] Verify the distro-family `case` statement's matching
      logic directly for all four branches (Debian/Ubuntu, RHEL/Fedora/
      CentOS, Arch, unrecognized-fallback), after an initial in-process
      function test gave misleading results due to sourcing this
      sandbox's own real `/etc/os-release`

**Checkpoint**: `install.sh` no longer hands the Nix installer a system
missing one of its own real prerequisites
