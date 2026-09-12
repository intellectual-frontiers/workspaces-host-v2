---

description: "Task list for Port the Original oh-my-posh Theme"

---

# Tasks: Port the Original oh-my-posh Theme

**Input**: Design documents from `/specs/008-port-original-theme/`

## Phase 1: User Story 1 - Exact theme port (P1) 🎯

- [x] T001 [US1] Fetch `strategy-coach/workspaces-host`'s
      `dot_config/oh-my-posh/coach.omp.json` and copy it byte-for-byte to
      `themes/oh-my-posh/coach.omp.json`; remove the old
      `default.omp.json` placeholder
- [x] T002 [US1] Update `home/shell.nix`'s `readFile` reference to the new
      filename
- [x] T003 [US1] Verify: `cmp` confirms byte-identity with the original;
      `nix build .#homeConfigurations.default.activationPackage` succeeds;
      a real activation's generated `~/.config/oh-my-posh/config.json`
      parses to the same JSON structure (Python `json.load` equality) as
      the checked-in file
- [x] T004 [US1] Verify: `oh-my-posh print primary` against the generated
      config renders correctly, including the git segment's background
      color change on a dirty working tree

**Checkpoint**: default profile's prompt is byte-for-byte the original
repo's theme

## Phase 2: Polish

- [x] T005 Run `nix flake check --all-systems`, confirm it still passes
