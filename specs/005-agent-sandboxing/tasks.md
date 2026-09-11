---

description: "Task list for Agent Sandboxing"

---

# Tasks: Agent Sandboxing

**Input**: Design documents from `/specs/005-agent-sandboxing/`

## Phase 1: User Story 1 - Non-root + default-deny egress (P1) 🎯 MVP

- [x] T001 [US1] Implement `pkgs/init-firewall/init-firewall`: resolve
      allowlisted domains via `getent ahostsv4`, populate an `ipset`,
      wire a dedicated `iptables` chain (loopback/established/DNS/ipset
      accept, else drop), self-check (a known-bad domain must fail, the
      first allowed domain must succeed), refuse to proceed on an empty
      resolved allowlist
- [x] T002 [US1] Implement `pkgs/init-firewall/default.nix`: wrap with
      `iptables`, `ipset`, `pkgs.getent` (not `glibc`/`glibc.bin` - verified
      by build failure that `getent` is its own nixpkgs output), `gawk`,
      `coreutils`, `curl`
- [x] T003 [US1] Add to `pkgs/default.nix`'s aggregate
- [x] T004 [US1] Implement `oci/sandboxed.nix`: custom `/etc/passwd`,
      `/etc/group`, `/etc/nsswitch.conf` (needed for `getent` to actually
      use DNS - verified by build failure without it) providing a
      non-root `agent` user (uid/gid 1000), reusing
      `homeConfig.config.home.packages`/dotfiles like `oci/default.nix`
- [x] T005 [US1] Implement `oci/sandboxed-entrypoint.sh`: run
      `init-firewall` (unless `SKIP_FIREWALL=1`), then
      `exec setpriv --reuid=agent --regid=agent --clear-groups --inh-caps=-all "$@"`
- [x] T006 [US1] Wire `packages.<system>.oci-image-sandboxed` in
      `flake.nix`
- [x] T007 [US1] Verify against a real `docker run --cap-add=NET_ADMIN
      --cap-add=NET_RAW`: `id` reports uid 1000; a stable-IP allowlisted
      domain succeeds; a non-allowlisted domain times out; `iptables -L`
      as `agent` is refused

**Checkpoint**: non-root execution + default-deny egress both verified
against a real running container

## Phase 2: User Story 2 - Configurable allowlist (P2)

- [x] T008 [US2] `init-firewall` reads `$FIREWALL_ALLOWED_DOMAINS`,
      falling back to a built-in default list (covered by T001)
- [x] T009 [US2] Verify: run with `FIREWALL_ALLOWED_DOMAINS` set to a
      single custom domain, confirm the self-check log reports exactly
      that list and only that domain is reachable

## Phase 3: Polish

- [x] T010 Run `nix flake check --all-systems`, confirm both new
      packages evaluate cleanly on all four systems and build on
      x86_64-linux
- [x] T011 Write `specs/005-agent-sandboxing/quickstart.md`, including
      the CDN-rotating-IP caveat discovered during T007's verification
      (documented honestly, not glossed over)
- [x] T012 Update `README.md`'s roadmap table to mark Phase 5 complete

## Dependencies & Execution Order

User Story 2 only needed verification (T009) - the configurability itself
(T008) was already part of `init-firewall`'s User Story 1 implementation,
since a hardcoded allowlist wouldn't have made sense to write twice.
