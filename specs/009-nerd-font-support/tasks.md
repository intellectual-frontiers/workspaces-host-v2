---

description: "Task list for Nerd Font Support"

---

# Tasks: Nerd Font Support

**Input**: Design documents from `/specs/009-nerd-font-support/`

## Phase 1: User Story 1 - Font installs automatically (P1) 🎯

- [x] T001 [US1] Confirm `"JetBrainsMono"` is a valid `pkgs.nerdfonts`
      override key and its release asset is reachable in this sandbox
- [x] T002 [US1] Create `home/fonts.nix`:
      `fonts.fontconfig.enable = true;` +
      `home.packages = [ (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; }) ];`
- [x] T003 [US1] Import `./fonts.nix` in `home/default.nix`
- [x] T004 [US1] Verify: `nix build .#homeConfigurations.default.activationPackage`
      succeeds (font package builds cleanly)
- [x] T005 [US1] Verify: real activation as the `workspace` user installs the
      font; `fc-list` confirms `JetBrainsMono Nerd Font`,
      `JetBrainsMono Nerd Font Mono`, and `JetBrainsMono Nerd Font Propo`
      families are present

**Checkpoint**: every profile gets the patched font installed automatically

## Phase 2: User Story 2 - Human font-selection instructions (P1) 🎯

- [x] T006 [US2] Determine the *exact* family name to document from T005's
      real `fc-list` output rather than assuming one
      (`JetBrainsMono Nerd Font Mono`, alias `JetBrainsMono NFM`)
- [x] T007 [US2] Add README.md step 6 under Installation: verification
      command, exact family name + why the Mono variant specifically,
      WSL2/Windows Terminal steps (including the Windows-side font install,
      since WSL2's Linux font isn't visible to Windows GDI), Linux VM/Debian
      GNOME Terminal steps, and a generic fallback for other terminal
      emulators

**Checkpoint**: an engineer who just activated this flake has a documented,
exact path to actually seeing the prompt's icons render

## Phase 3: Polish

- [x] T008 Run `nix flake check --all-systems`, confirm it still passes
