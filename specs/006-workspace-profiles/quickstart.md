# Quickstart: Workspace Profiles

Verified during implementation on x86_64-linux.

## 1. Build all four personas

```console
$ for p in backend data mobile agent-ops; do
    nix build .#homeConfigurations.$p.activationPackage --no-link
  done
# all four succeed
```

## 2. Activate one and confirm base + persona-specific tools coexist

```console
$ home-manager switch --flake .#backend
...
$ which fish semtag specify backlog   # from the shared base
$ which psql redis-cli docker-compose http   # backend-specific
```

Both sets resolve - the persona profile is strictly additive over the
base, not a separate, duplicated list.

## 3. Compare persona package sets

```console
$ nix eval .#homeConfigurations.backend.config.home.packages --apply 'ps: map (p: p.pname or p.name) ps'
$ nix eval .#homeConfigurations.data.config.home.packages --apply 'ps: map (p: p.pname or p.name) ps'
```

The two lists share every base-profile package (fish, oh-my-posh, direnv,
git, semtag/mgitstatus/git-standup, specify-cli, backlog-md,
scaffold-agent-harness, sensitivectl, ripgrep/fd/jq/bat/eza/fzf) and
differ only in each persona's own additions.
