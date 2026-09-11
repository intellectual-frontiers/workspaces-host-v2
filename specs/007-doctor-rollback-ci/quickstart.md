# Quickstart: Doctor + Rollback + CI

Verified during implementation on x86_64-linux (`doctor`/rollback) and by
opening this feature's own pull request (CI).

## 1. doctor

```console
$ home-manager switch --flake .#default
$ doctor
workspaces-host doctor
======================

-- Nix --
PASS  nix is on PATH (nix (Nix) 2.29.1)
PASS  nix-command and flakes experimental features are enabled
PASS  home-manager is on PATH (...)

-- Shell / prompt / direnv --
PASS  fish is on PATH (...)
PASS  oh-my-posh is on PATH (...)
PASS  direnv is on PATH (...)
PASS  nix-direnv integration file present

-- Git --
PASS  git is on PATH (...)
PASS  git user.email is set (...)

-- Ported CLI tools (home.packages) --
PASS  semtag is on PATH (...)
PASS  mgitstatus is on PATH (...)
PASS  git-standup is on PATH (...)
PASS  specify is on PATH (...)
PASS  backlog is on PATH (...)
PASS  scaffold-agent-harness is on PATH (...)
PASS  sensitivectl is on PATH (...)

-- Optional: container tooling --
PASS  docker is on PATH (...)

doctor: all checks passed (WARNs, if any, are informational)
$ echo $?
0
```

With a deliberately broken `PATH` (simulating a missing tool), the same
run reports `FAIL` lines and exits `1` - verified during implementation.

## 2. Rollback (home-manager generations - no new tooling)

```console
$ home-manager switch --flake .#default        # generation 1
$ cat ~/.rollback-test-marker
cat: .../.rollback-test-marker: No such file or directory

# ... make a change, e.g. edit home/*.nix to add a file ...
$ home-manager switch --flake .#default        # generation 2
$ cat ~/.rollback-test-marker
generation-2

$ home-manager generations
2026-09-11 22:15 : id 2 -> /nix/store/...-home-manager-generation
2026-09-11 22:15 : id 1 -> /nix/store/...-home-manager-generation

$ /nix/store/...-home-manager-generation/activate   # generation 1's own path
$ cat ~/.rollback-test-marker
cat: .../.rollback-test-marker: No such file or directory   # gone - rolled back
```

This exact cycle (with a throwaway `home.file` marker standing in for
"some change you want to undo") was run during implementation and
behaved as shown. Rolling forward again is symmetric: re-activate
generation 2's path.

## 3. CI

`.github/workflows/ci.yml` runs on every push to `main` and every pull
request:

1. `nix flake check --all-systems` - builds every check/package for the
   runner's system, evaluates the rest.
2. Explicit `nix build` of `packages.x86_64-linux.oci-image` and
   `.oci-image-sandboxed`.
3. Activates `homeConfigurations.default` and runs `doctor` against that
   real activation.

This feature's own pull request is the first real run of this workflow -
see the PR's checks tab for the live result.
