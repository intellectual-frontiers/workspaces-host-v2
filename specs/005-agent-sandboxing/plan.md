# Implementation Plan: Agent Sandboxing

**Branch**: `005-agent-sandboxing` | **Date**: 2026-09-11 | **Spec**: [spec.md](./spec.md)

## Summary

Add `pkgs/init-firewall` (default-deny egress + ipset allowlist +
self-check, over `iptables`/`ipset`/`getent`/`curl`) and
`oci/sandboxed.nix` (an OCI image reusing Phase 2's
`homeConfig.config.home.packages`/dotfiles, plus a baked-in non-root
`agent` user and an entrypoint that runs the firewall as root then
`setpriv`s down to `agent` before exec'ing the workload).

## Technical Context

**Language/Version**: POSIX `sh` (`init-firewall`, `sandboxed-entrypoint`),
Nix (packaging + image assembly).

**Primary Dependencies**: `pkgs.iptables`, `pkgs.ipset`, `pkgs.getent`
(nixpkgs splits `getent` out of `glibc` as its own output/alias
specifically for minimal-image use - not `glibc.bin`, which lacks it),
`pkgs.curl`, `pkgs.gawk`, `pkgs.util-linux` (`setpriv`). All already in
nixpkgs, no new flake input.

**Storage**: N/A.

**Testing**: Real Docker run with `--cap-add=NET_ADMIN --cap-add=NET_RAW`
against the actual built image - not a description of intended behavior.
This session's sandbox routes all outbound HTTPS through its own
TLS-intercepting egress proxy, so verification needed that proxy's CA
mounted into the test container (`-v .../ca-bundle.crt:... -e
SSL_CERT_FILE=...`); that's an artifact of *this development sandbox*,
not something the shipped image requires - a normal deployment's egress
path doesn't need it.

**Target Platform**: Linux only. Unlike `oci-image` (Phase 2), `iptables`/
`ipset` declare themselves unsupported on Darwin via nixpkgs'
`meta.badPlatforms`, which fails *evaluation*, not just building - so
`init-firewall` and `oci-image-sandboxed` are only added to
`packages.<system>` for the two Linux systems (discovered by `nix flake
check --all-systems` failing outright until this was fixed), rather than
being listed (and merely unbuildable) on Darwin the way `oci-image` is.

**Project Type**: Additions to the existing single Nix project.

**Constraints**: No new flake inputs. Must not silently degrade to
unfirewalled on any failure path (spec FR-002, FR-005).

**Scale/Scope**: One firewall script, one image variant. IPv6 and
non-Linux egress control are explicitly out of scope (spec Assumptions).

## Constitution Check

- **Principle I**: No new inputs; pinned by the same `flake.lock`.
- **Principle II**: The firewall is (re-)applied fresh on every container
  start from the entrypoint - no persisted, driftable firewall state.
- **Principle III**: N/A directly, but in the same spirit: the non-root
  `agent` user cannot escalate back to modifying its own network
  restrictions (verified: `iptables -L` as `agent` is refused).
- **Principle IV**: `oci-image-sandboxed` is built from the exact same
  `homeConfig` Phase 1/2 already produce - no separate package list.
- **Principle V**: Single feature, single PR.

No violations.

## Project Structure

```text
pkgs/init-firewall/
├── default.nix
└── init-firewall

oci/
├── sandboxed.nix               # dockerTools.buildLayeredImage variant
└── sandboxed-entrypoint.sh     # root: init-firewall, then setpriv to `agent`

flake.nix                        # packages.<system>.oci-image-sandboxed added
                                  # alongside oci-image

specs/005-agent-sandboxing/
├── plan.md
├── quickstart.md
└── tasks.md
```

**Structure Decision**: `oci/sandboxed.nix` sits alongside `oci/default.nix`
rather than parameterizing the existing one, since the two images differ
in more than a flag - a distinct root user model, an entrypoint, and
firewall tooling - and keeping them as separate small files is clearer
than one file branching on a `sandboxed` argument.

## Complexity Tracking

*No constitution violations - table not needed.*
