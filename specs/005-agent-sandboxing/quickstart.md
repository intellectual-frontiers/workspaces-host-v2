# Quickstart: Agent Sandboxing

Verified during implementation with real `docker run` invocations against
this flake's own built image - not a description of intended behavior.

## 1. Build and load the sandboxed image

```console
$ nix build .#packages.x86_64-linux.oci-image-sandboxed
$ docker load -i result
Loaded image: workspaces-host-sandboxed:latest
```

## 2. Run it with the required capabilities

```console
$ docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
    workspaces-host-sandboxed:latest id
init-firewall: allowlisted domains: api.anthropic.com github.com ...
init-firewall: rules applied, running self-check
init-firewall: self-check passed - egress is default-deny with 9 domain(s) allowed
uid=1000(agent) gid=1000(agent) groups=1000(agent)
```

Non-root execution and firewall application both happen automatically,
before the workload command (`id` here) runs.

## 3. Allowed vs. blocked egress, as the non-root user

```console
$ docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
    -e FIREWALL_ALLOWED_DOMAINS="api.anthropic.com" \
    workspaces-host-sandboxed:latest sh -c '
      curl -s -o /dev/null -w "allowed: HTTP %{http_code}\n" https://api.anthropic.com
      curl -s -o /dev/null -w "blocked: HTTP %{http_code}\n" https://example.com || echo "blocked: connection failed (expected)"
    '
allowed: HTTP 404
blocked: connection failed (expected)
```

(`HTTP 404` for the allowed domain means the TLS connection and HTTP
request both succeeded - the API simply doesn't answer a bare `GET /`.
The blocked domain times out at the TCP level, well before any
HTTP response.)

## 4. The non-root user cannot touch the firewall

```console
$ docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
    workspaces-host-sandboxed:latest sh -c 'iptables -L WORKSPACES-HOST-EGRESS'
iptables v1.8.10 (nf_tables): Could not fetch rule set generation id: Permission denied (you must be root)
```

## A caveat found during real testing: CDN-backed domains

`init-firewall` resolves each allowlisted domain to its A record(s)
*once*, at startup, and only those specific IPs are allowlisted. Testing
against `github.com` (served by a large, multi-IP CDN) showed `getent`
resolving one IP at firewall-setup time and a later `curl` resolving a
*different* IP for the same hostname - which then got blocked, since it
wasn't one of the IPs allowlisted at startup.

This is not a bug in this implementation; it's an inherent limitation of
IP-based (rather than SNI-aware/proxy-based) domain allowlisting, shared
by Anthropic's own reference firewall this feature is modeled on.
Practical mitigation: prefer domains with small/stable IP pools for
anything latency-sensitive inside the sandbox, or re-run `init-firewall`
if a CDN-backed domain starts failing partway through a long-running
session.

## Opting out (debugging only)

```console
$ docker run --rm -e SKIP_FIREWALL=1 workspaces-host-sandboxed:latest id
sandboxed-entrypoint: SKIP_FIREWALL=1 set - running with unrestricted egress
uid=1000(agent) gid=1000(agent) groups=1000(agent)
```

Non-root execution still applies even with the firewall skipped - the two
protections are independent.
