# Feature Specification: Java Toolchain

**Feature Branch**: `015-java-toolchain`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "Implement #7: Java toolchain - use either SDKMAN! or whatever Nix-specific Java manager is more 'built-in'."

## Background

The original repo bootstrapped SDKMAN! and used it to opt-in install a
JDK (Amazon Corretto 21) and Maven via a `setup-java-amazon-corretto` fish
function, with `JAVA_HOME` pointed at SDKMAN!'s `current` symlink
(`dot_config/fish/conf.d/java.fish`,
`dot_config/fish/functions/setup-java-amazon-corretto.fish`). This
rewrite had no Java tooling at all - not even a `doctor` section for it,
confirmed absent everywhere in `home/*.nix` and every persona profile.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - `java`/`mvn` work out of the box (Priority: P2)

An engineer runs `java`/`mvn` immediately after activating any profile,
with `JAVA_HOME` already correct - no separate install step, no version
manager to invoke first.

**Independent Test**: Activate the `default` profile; run `java -version`
and `mvn -version` in a real shell; confirm `JAVA_HOME` points at a valid,
Nix-store JDK and Maven resolves that same JDK (not an ambient system
one).

**Acceptance Scenarios**:

1. **Given** an activated profile, **When** `java -version` runs, **Then**
   it reports the nixpkgs-pinned OpenJDK version.
2. **Given** the same profile, **When** `mvn -version` runs inside a real
   login/interactive shell (where `home.sessionVariables` actually
   apply), **Then** its reported "Java version"/"runtime" is the same
   Nix-store JDK `JAVA_HOME` points at, not an unrelated system JDK that
   might also happen to be on the machine.

---

### Edge Cases

- A machine with its own ambient `JAVA_HOME`/system JDK (common - many
  CI/dev environments have one pre-installed) must still resolve `mvn` to
  *this* module's JDK when running inside an activated profile's shell,
  since `home.sessionVariables.JAVA_HOME` takes precedence in that shell
  - verified explicitly (not assumed) since a raw non-interactive shell
  that never sourced home-manager's session vars would show the ambient
  JDK instead, which is expected (it isn't using this profile) rather
  than a bug in the module.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `home/java.nix` MUST install a JDK and Maven from nixpkgs
  via `home.packages`.
- **FR-002**: `home/java.nix` MUST set `home.sessionVariables.JAVA_HOME`
  to that JDK's home directory.
- **FR-003**: `pkgs/doctor/doctor` MUST report `java`/`mvn` on PATH, the
  Java version, and whether `$JAVA_HOME` is set and points at a valid
  `bin/java`.
- **FR-004**: README.md MUST document the choice of nixpkgs-native
  JDK/Maven over a second version manager (SDKMAN!) layered on top of Nix,
  and how to override the pinned JDK/Maven in a fork.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix build .#homeConfigurations.default.activationPackage`
  succeeds with `home/java.nix` included.
- **SC-002**: A real activation's `java -version` reports the
  nixpkgs-pinned version; `mvn -version` run inside a real fish shell
  (not a bare non-interactive shell) resolves the same JDK via
  `JAVA_HOME`, verified by comparing the printed Java runtime path against
  `$JAVA_HOME`.
- **SC-003**: `nix flake check --all-systems` continues to pass.

## Assumptions

- **nixpkgs' own `jdk`/`maven` packages, not SDKMAN!, are the right
  choice for this repo.** SDKMAN! is itself a version manager; this repo
  is already built on Nix, which is a real, reproducible version manager
  for every other tool it provides (pinned via `flake.lock`). Installing
  SDKMAN! on top would mean two version managers doing the same job, with
  SDKMAN!'s own installs living outside the Nix store (unpinned,
  unreproducible, invisible to `nix flake check`) - the opposite of this
  project's Constitution Principle I. `pkgs.jdk` in this flake's pinned
  nixpkgs (24.11) resolves to OpenJDK 21 at the time of writing; an
  engineer who wants a specific vendor/version (e.g. Amazon Corretto, to
  match the original repo exactly, or a different LTS) overrides
  `home/java.nix` in a fork, the same pattern as every other opinionated
  default here.
- Only a JDK + Maven are provisioned (matching what the original actually
  used - Corretto + Maven; its Kotlin line was itself commented out as a
  TODO, never implemented) - Gradle or other build tools are out of scope
  unless requested.
