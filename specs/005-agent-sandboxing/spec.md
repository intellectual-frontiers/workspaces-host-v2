# Feature Specification: Agent Sandboxing

**Feature Branch**: `005-agent-sandboxing`

**Created**: 2026-09-11

**Status**: Draft

**Input**: User description: "Agent sandboxing: a network-egress-allowlist profile for agent execution, modeled on Anthropic's reference Claude Code devcontainer firewall (non-root user, restricted egress)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - An agent container runs as non-root with default-deny egress (Priority: P1)

An operator runs `packages.<system>.oci-image-sandboxed` (built with
`--cap-add=NET_ADMIN --cap-add=NET_RAW`) as the environment an AI coding
agent executes in. The agent's actual workload runs as a non-root `agent`
user, and outbound network access is default-deny except for a
declared allowlist of domains - matching Anthropic's own reference Claude
Code devcontainer firewall model.

**Why this priority**: This is the entire feature - without both halves
(non-root execution *and* restricted egress), it isn't "agent sandboxing,"
just a container.

**Independent Test**: Run the image with the required capabilities,
confirm `id` inside the running workload reports a non-root UID, and
confirm (from that same non-root context) a request to an allowlisted
domain succeeds while a request to a non-allowlisted domain fails/times
out.

**Acceptance Scenarios**:

1. **Given** the sandboxed image run with `--cap-add=NET_ADMIN
   --cap-add=NET_RAW`, **When** the container starts, **Then** the
   firewall is applied *before* the workload command runs, and the
   workload itself executes as `agent` (uid 1000), not root.
2. **Given** the firewall applied with domain X on the allowlist, **When**
   a request is made to X from the running (non-root) workload, **Then**
   it succeeds.
3. **Given** the same setup, **When** a request is made to a
   non-allowlisted domain, **Then** it fails (connection times out /
   refused) rather than succeeding.
4. **Given** the workload is running as `agent`, **When** it attempts to
   modify the firewall's own `iptables` rules, **Then** it is refused
   with a permission error (non-root cannot re-open its own cage).

---

### User Story 2 - The allowlist is configurable, not hardcoded (Priority: P2)

An operator overrides `FIREWALL_ALLOWED_DOMAINS` (a space-separated list)
to add or replace the default allowlist for their specific agent
workload, without editing this repository.

**Why this priority**: A fixed allowlist baked into the image would force
a fork for every project's different tool needs; this is what makes the
feature usable beyond this repo's own default toolset.

**Independent Test**: Run the image with `-e
FIREWALL_ALLOWED_DOMAINS="single-domain.example"` and confirm the
firewall's self-check log reports exactly that one domain, and that only
it is reachable.

**Acceptance Scenarios**:

1. **Given** `FIREWALL_ALLOWED_DOMAINS` set to a custom list, **When**
   the container starts, **Then** `init-firewall`'s log reports that
   exact list (not the built-in default).

---

### Edge Cases

- **CDN-backed domains resolve to multiple/rotating IPs.** `init-firewall`
  resolves each allowed domain to its A records *once*, at startup, and
  allowlists exactly those IPs. A domain served by a large CDN (observed
  during implementation: `github.com`, which returned a different IP to
  a later `curl` than the one `getent` had returned moments earlier) can
  intermittently fail even though it's on the allowlist, because the
  specific IP a later DNS lookup returns wasn't one of the IPs resolved
  at firewall-init time. This is a known, inherent limitation of
  IP-based (rather than SNI/proxy-based) domain allowlisting - the same
  limitation Anthropic's own reference implementation carries. Mitigation
  is operational, not a code fix: prefer allowlisting domains with small,
  stable IP sets for anything latency-sensitive, or re-run
  `init-firewall` if a CDN-backed domain starts failing mid-session.
- **No `NET_ADMIN`/`NET_RAW` granted.** `init-firewall` requires root
  privileges within the container's user namespace and those two
  capabilities to write `iptables`/`ipset` rules; if they're missing, it
  fails with a permission error at startup (via `iptables`/`ipset`
  themselves) rather than silently running unfirewalled. An operator who
  genuinely wants no firewall passes `SKIP_FIREWALL=1` explicitly - there
  is no silent fallback.
- **Empty or entirely-unresolvable allowlist.** `init-firewall` refuses
  to proceed (exits non-zero) rather than either applying a no-op
  "firewall" or bricking all networking by accident - see the script's
  own explicit check.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The flake MUST provide an `init-firewall` command
  (`packages.<system>.init-firewall`) that, given a space-separated list
  of domains (via `$FIREWALL_ALLOWED_DOMAINS`, falling back to a built-in
  default list), resolves each to its IPv4 addresses and configures
  `iptables`/`ipset` so that only loopback, DNS, established/related
  traffic, and traffic to those resolved IPs is permitted - everything
  else is dropped.
- **FR-002**: `init-firewall` MUST self-verify its own rules immediately
  after applying them (a known-non-allowlisted domain must fail; the
  first allowlisted domain must succeed) and MUST exit non-zero if either
  check fails, rather than leaving a broken firewall silently in place.
- **FR-003**: The flake MUST provide
  `packages.<system>.oci-image-sandboxed`: an OCI image built from the
  same `homeConfig.config.home.packages`/dotfiles as
  `packages.<system>.oci-image` (Phase 2), plus `iptables`, `ipset`, and
  `init-firewall`, with a non-root `agent` user (uid/gid 1000) baked into
  its `/etc/passwd`/`/etc/group`.
- **FR-004**: The sandboxed image's entrypoint MUST run `init-firewall`
  as root, then drop privileges (via `setpriv`, clearing supplementary
  groups and inheritable capabilities) to the `agent` user before
  exec'ing the actual workload command (default: `fish`).
- **FR-005**: The entrypoint MUST support `SKIP_FIREWALL=1` as an
  explicit, documented opt-out (for local debugging where the container
  runtime doesn't grant `NET_ADMIN`), never as an implicit fallback on
  firewall failure.
- **FR-006**: The `agent` user MUST NOT have the capabilities or
  privileges needed to modify the firewall rules `init-firewall`
  established.

### Key Entities

- **`init-firewall`**: the firewall-setup-and-self-check script.
- **`oci-image-sandboxed`**: the OCI image wiring `init-firewall` and the
  non-root `agent` user around Phase 2's package/dotfile closure.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Running `oci-image-sandboxed` with the required
  capabilities results in the workload executing as a non-root UID,
  verified via `id`.
- **SC-002**: From that non-root workload, a request to a
  small-stable-IP allowlisted domain succeeds and a request to a
  non-allowlisted domain fails - verified against real network requests,
  not mocked.
- **SC-003**: The non-root `agent` user's attempt to read/modify the
  live `iptables` ruleset is refused with a permission error.
- **SC-004**: `nix flake check --all-systems` continues to pass overall;
  `init-firewall` and `oci-image-sandboxed` are added to
  `packages.<system>` only for the two Linux systems, since `iptables`/
  `ipset` are marked unsupported on Darwin at the nixpkgs level (an
  eval-time restriction, not just a build-time one - discovered when
  `--all-systems` failed outright before this was scoped correctly).

## Assumptions

- The container runtime running `oci-image-sandboxed` grants
  `--cap-add=NET_ADMIN --cap-add=NET_RAW` (or the equivalent under
  Kubernetes/another orchestrator); without them, `init-firewall` cannot
  do its job and fails loudly by design (FR-002), rather than degrading
  silently to unfirewalled.
- The default allowlist (`api.anthropic.com`, `github.com`,
  `objects.githubusercontent.com`, `raw.githubusercontent.com`,
  `registry.npmjs.org`, `pypi.org`, `files.pythonhosted.org`,
  `cache.nixos.org`, `releases.nixos.org`) is a reasonable starting point
  for an agent doing typical coding-agent work against this repo's own
  toolchain; per User Story 2, any project overrides it via
  `FIREWALL_ALLOWED_DOMAINS` for its own needs.
- IPv6 egress is out of scope for this feature's allowlist (IPv4 only,
  via `getent ahostsv4`) - a project needing IPv6 egress control extends
  `init-firewall` itself, which isn't precluded by this design.
