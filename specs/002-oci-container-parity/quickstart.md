# Quickstart: Container/OCI Parity

Verified during implementation on x86_64-linux with Docker 29.3.1.

## 1. Build the image (no container runtime required)

```console
$ nix build .#packages.x86_64-linux.oci-image
```

Produces `./result`, a `docker load`-able tarball, built by
`dockerTools.buildLayeredImage` from the exact same
`homeConfigurations.x86_64-linux.config` Phase 1's host profile uses -
this step succeeds even without Docker installed.

## 2. Load and run it

```console
$ docker load -i result
Loaded image: workspaces-host:latest

$ docker run --rm workspaces-host:latest fish -c \
    'fish --version; git config --get user.name; git config --get user.email; oh-my-posh --version'
fish, version 3.7.1
Workspace Engineer
workspace@example.invalid
23.20.3
```

## 3. Confirm every tool resolves on PATH

```console
$ docker run --rm workspaces-host:latest fish -c \
    'for c in oh-my-posh git direnv semtag mgitstatus git-standup fish; type -p $c; end'
/sbin/oh-my-posh
/sbin/git
/sbin/direnv
/sbin/semtag
/sbin/mgitstatus
/sbin/git-standup
/sbin/fish
```

(`type -p` is used instead of `which`, which the minimal image doesn't
include - matches the image's slim intent.)

## 4. Functional check of the ported scripts

```console
$ docker run --rm workspaces-host:latest bash -lc '
    cd /tmp && git init -q repo && cd repo &&
    git config user.email a@b.c && git config user.name t &&
    echo hi > f && git add f && git commit -q -m init &&
    semtag list; semtag final -s patch -a; git tag'
v0.0.1
semtag: created tag v0.0.1
v0.0.1
```

All four steps were run against the actual image during implementation -
this is not a hypothetical procedure.
