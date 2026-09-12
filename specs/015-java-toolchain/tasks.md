---

description: "Task list for Java Toolchain"

---

# Tasks: Java Toolchain

**Input**: Design documents from `/specs/015-java-toolchain/`

## Phase 1: User Story 1 - `java`/`mvn` out of the box (P2) 🎯

- [x] T001 [US1] Confirm `pkgs.jdk`/`pkgs.maven` exist in this flake's
      pinned nixpkgs (24.11) and check `pkgs.jdk.home`'s exact path
      convention (`openjdk/generic.nix`'s `passthru.home`)
- [x] T002 [US1] Create `home/java.nix`: `home.packages = [ pkgs.jdk
      pkgs.maven ]`, `home.sessionVariables.JAVA_HOME = "${pkgs.jdk.home}"`
- [x] T003 [US1] Import `./java.nix` in `home/default.nix`
- [x] T004 [US1] Verify: `nix build
      .#homeConfigurations.default.activationPackage` succeeds
- [x] T005 [US1] Verify: real activation's `java -version` reports the
      pinned OpenJDK version; `mvn -version` run inside a real fish shell
      resolves the same JDK via `$JAVA_HOME` (checked explicitly against a
      bare non-interactive shell, which - correctly - shows an unrelated
      ambient JDK instead, since it never sourced session variables)

**Checkpoint**: every profile has a working, correctly-wired `java`/`mvn`

## Phase 2: Polish

- [x] T006 Add `java`/`mvn`/`$JAVA_HOME` checks to `pkgs/doctor/doctor`
- [x] T007 Write README's "Java toolchain" section: what's installed, why
      nixpkgs directly rather than SDKMAN! (Assumptions), how to override
      the pinned JDK/Maven in a fork
- [x] T008 Add README's macOS Installation subsection (real, since this
      flake already supports `x86_64-darwin`/`aarch64-darwin` - the
      `default` alias caveat, the per-system build/switch commands) and a
      short, honest Windows-native subsection (not supported without
      WSL2, which is already documented above)
- [x] T009 Run `nix flake check --all-systems`, confirm it passes
