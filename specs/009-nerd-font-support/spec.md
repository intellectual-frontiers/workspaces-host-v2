# Feature Specification: Nerd Font Support

**Feature Branch**: `009-nerd-font-support`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "Add Nerd Font support so the ported coach.omp.json theme's icons actually render, with crucial human-facing documentation since selecting a font in a terminal emulator is an inherently manual, per-application step home-manager cannot automate."

## Background

Feature 008 ported `strategy-coach/workspaces-host`'s actual `coach.omp.json`
theme byte-for-byte. That theme's OS/git/language/clock segments are drawn
with Nerd Font private-use-area glyphs. Neither the original repo nor this
one previously provisioned a Nerd Font, so on a machine without one already
installed, those segments render as tofu boxes or `?` instead of icons.
Nix/home-manager can install a font file into a user's profile, but it
cannot select that font inside a GUI terminal emulator (Windows Terminal,
GNOME Terminal, iTerm2, kitty, ...) - that is a per-application setting only
a human can make. This feature covers both halves: the automatable
installation, and - just as important - the human instructions for the part
that isn't automatable.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The font is installed automatically (Priority: P1)

An engineer activates any profile of this flake and gets a patched Nerd Font
in their user profile without any extra step.

**Why this priority**: Prerequisite for the icons to be selectable at all;
this is the part Nix can actually do for the engineer.

**Independent Test**: Activate the `default` profile; confirm via `fc-list`
that `JetBrainsMono Nerd Font Mono` (and siblings) are present under
`~/.nix-profile/share/fonts/truetype/NerdFonts/`.

**Acceptance Scenarios**:

1. **Given** a fresh activation of any profile, **When** `fc-list | grep
   "JetBrainsMono Nerd Font"` is run, **Then** the patched font families are
   listed.
2. **Given** the flake, **When** built for any of its supported systems,
   **Then** `nix build .#homeConfigurations.default.activationPackage`
   succeeds (the font package fetches and builds cleanly).

---

### User Story 2 - The engineer knows how to actually see the icons (Priority: P1)

An engineer who just activated this flake for the first time, and sees tofu
boxes instead of icons in their prompt, has a documented, exact set of steps
to fix it for their specific environment (WSL2/Windows Terminal, Linux
VM/GNOME Terminal, Debian bare metal, or "some other terminal emulator").

**Why this priority**: Equal priority to US1 - installing the font file
achieves nothing on its own if the engineer doesn't know the terminal itself
needs to be told to use it, and doesn't know the exact family name to enter.
This is the step most likely to be silently skipped or gotten wrong (e.g.
picking the non-Mono variant, which misaligns the theme's powerline
segments).

**Independent Test**: Follow README.md's new step 6 verbatim on a real
GNOME Terminal profile; confirm the OS/branch icons render afterward.

**Acceptance Scenarios**:

1. **Given** README.md's installation steps, **When** an engineer reaches
   step 6, **Then** they find the exact font family name to select
   (`JetBrainsMono Nerd Font Mono`), a command to verify it's installed
   first, and concrete steps for each of this project's three documented
   environments.
2. **Given** the Mono vs. plain Nerd Font variant ambiguity, **When** the
   engineer reads step 6, **Then** they're told which one to pick and why
   (fixed-width icon glyphs keep the theme's diamond/powerline segments
   aligned).

---

### Edge Cases

- WSL2 is a split case: the font must be installed on the **Windows** side
  (Windows Terminal renders with GDI, which cannot see fonts installed only
  inside the WSL2 Linux filesystem) as well as the Linux side that
  home-manager already covers - documented explicitly since it's easy to
  miss.
- This feature does not attempt to auto-configure any terminal emulator's
  font setting (no `dconf` scripting for GNOME Terminal, no Windows
  Terminal `settings.json` patching) - out of scope, since engineers use a
  wide variety of terminal emulators this flake has no reason to assume or
  special-case, and directly editing a GUI application's own settings file
  from a dotfiles manager is fragile compared to one documented manual step.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `home/fonts.nix` MUST install a Nerd Font patched font family
  (JetBrainsMono, matching a common monospace choice) into the user
  profile via `home.packages`, for every profile built from `home/`.
- **FR-002**: `home/fonts.nix` MUST enable `fonts.fontconfig` so the
  installed font is discoverable by fontconfig-based applications.
- **FR-003**: README.md MUST document, per supported environment
  (WSL2/Windows Terminal, Linux VM, Debian bare metal, and a generic
  fallback for other terminal emulators), the exact steps and exact font
  family name required to make the terminal actually render with the
  installed font.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix build .#homeConfigurations.default.activationPackage`
  succeeds with the font module included.
- **SC-002**: A real activation installs the font; `fc-list` confirms the
  exact family names documented in the README are the ones actually
  produced by the build (no guessing/assuming a name).
- **SC-003**: `nix flake check --all-systems` continues to pass.

## Assumptions

- JetBrainsMono is an acceptable default font choice (it's a common,
  liberally-licensed monospace font already popular in the Nerd Fonts
  ecosystem); engineers who prefer a different Nerd Font override
  `home/fonts.nix`'s `fonts` list in a fork, same pattern as other
  identity/preference overrides in this project (git identity, etc.).
- This sandbox cannot itself render a GUI terminal, so "the icons render"
  is verified via `fc-list` (font is installed and discoverable) and
  `oh-my-posh print primary`'s raw output (correct glyphs are emitted, not
  fallback characters) rather than a literal screenshot of a themed
  terminal window.
