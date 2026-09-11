# Quickstart: Agent-Harness Scaffolding

Verified during implementation on x86_64-linux.

## 1. specify-cli

```console
$ nix build .#packages.x86_64-linux.specify-cli
$ ./result/bin/specify check
              ███████╗██████╗ ███████╗ ██████╗██╗███████╗██╗   ██╗
              ...
Checking for installed tools...
Check Available Tools
├── ● Antigravity (not found)
...
├── ● Claude Code (available)
...

$ ./result/bin/specify init --here --integration claude --script sh --force --non-interactive
# scaffolds .specify/, .claude/skills/speckit-*/SKILL.md, etc. into the cwd
```

## 2. backlog-md

```console
$ nix build .#packages.x86_64-linux.backlog-md
$ ./result/bin/backlog --version
1.51.0
$ ./result/bin/backlog --help
Usage: backlog [options] [command]
Backlog.md - Project management CLI
...
```

## 3. scaffold-agent-harness

```console
$ nix build .#packages.x86_64-linux.scaffold-agent-harness
$ mkdir /tmp/demo && ./result/bin/scaffold-agent-harness /tmp/demo
created: AGENTS.md
created: .mcp.json
created: .claude/skills/README.md
created: .claude/settings.json
created: .claude/hooks/session-start.sh

$ ./result/bin/scaffold-agent-harness /tmp/demo   # run again - nothing overwritten
skipped (exists): AGENTS.md
skipped (exists): .mcp.json
skipped (exists): .claude/skills/README.md
skipped (exists): .claude/settings.json
skipped (exists): .claude/hooks/session-start.sh
```

All three were run exactly as shown above against this repository's own
build during implementation - not a hypothetical transcript.

## 4. Everything together, via the host profile

```console
$ home-manager switch --flake .#default
$ specify --help    # resolves on PATH
$ backlog --version # resolves on PATH
$ scaffold-agent-harness --help  # resolves on PATH
```
