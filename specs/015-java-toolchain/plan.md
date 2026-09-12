# Implementation Plan: Java Toolchain

**Branch**: `015-java-toolchain` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add `home/java.nix` (nixpkgs `jdk` + `maven`, `JAVA_HOME` session
variable) to every profile, plus `doctor` checks. Bundled into this same
small PR: the last remaining documentation-only gap-analysis item -
Windows/macOS native install paths in README.md's Installation section
(macOS is genuinely supported by this flake already via
`x86_64-darwin`/`aarch64-darwin`, just undocumented; native Windows isn't
and can't be supported by Nix, so that's documented honestly as "use
WSL2, covered above" rather than inventing something misleading).

## Technical Context

**Language/Version**: Nix (`home.packages`/`home.sessionVariables`),
matches every other small `home/*.nix` module in this repo.

**Primary Dependencies**: `pkgs.jdk` (OpenJDK, resolves per the pinned
nixpkgs 24.11), `pkgs.maven` (both already present in this flake's pinned
nixpkgs, confirmed via the local nixpkgs source tree before writing any
code).

**Testing**: `nix build .#homeConfigurations.default.activationPackage`;
real activation + `java -version`/`mvn -version` run inside an actual
fish shell (not a bare non-interactive one, which wouldn't have sourced
`home.sessionVariables` and would misleadingly show an ambient system
JDK instead) to confirm `JAVA_HOME` resolution is real, not assumed.

**Constraints**: No new flake inputs; no second version manager (see
spec Assumptions).

## Constitution Check

- **Principle I**: No new inputs; JDK/Maven come from the already-pinned
  `nixpkgs`.
- **Principle V**: Single feature, single PR (the bundled README doc
  addition is genuinely small and touches only README.md, not code).

No violations.

## Project Structure

```text
home/java.nix        # new: jdk + maven, JAVA_HOME
home/default.nix     # updated: import ./java.nix
pkgs/doctor/doctor    # updated: java/mvn/JAVA_HOME checks
README.md            # new "Java toolchain" section + macOS/Windows Installation subsections
```
