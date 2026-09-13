{ config, lib, pkgs, ... }:

{
  # Where workspaces-host-v2 itself is cloned - used by
  # `workspaces-host-update` and the daily upstream-check nudge below.
  # Dotted (~/.workspaces-host-v2) so it stays out of the way of a plain
  # `ls`/directory listing in $HOME. Override this (e.g. in a fork, or
  # via `home.sessionVariables` in a wrapping module) if you cloned it
  # somewhere else (see README's install steps).
  home.sessionVariables.WORKSPACES_HOST_REPO = "${config.home.homeDirectory}/.workspaces-host-v2";

  programs.bash = {
    enable = true;

    shellAliases = {
      ll = "eza -lah --git";
      ls = "eza";
      cat = "bat --paging=never";
      g = "git";
    };

    # Fish's own signature interactive niceties - syntax highlighting,
    # autosuggestions from history - come from `blesh` (Bash Line Editor)
    # here instead, so bash gets the same feel without giving up
    # anything POSIX/bash-compatible tutorials and copy-pasted snippets
    # already assume. `mkMerge`/`mkOrder` control *where in the final
    # ~/.bashrc* each piece lands, since ble.sh's own docs are explicit
    # that it must be sourced before anything else that touches
    # readline/PROMPT_COMMAND (oh-my-posh, zoxide, fzf, all below), with
    # the actual `ble-attach` call deferred to the very end - printing
    # anything to stdout after attaching corrupts the prompt ble.sh is
    # already rendering. Everything else in this file (and
    # home/ai-harness.nix's credential wrappers) is left at the default
    # priority, which - unlike `types.str`, this is `types.lines`,
    # concatenated across every module that touches it, not a
    # single-winner override - simply sorts between these two explicit
    # boundaries.
    initExtra = lib.mkMerge [
      (lib.mkOrder 10 ''
        source ${pkgs.blesh}/share/blesh/ble.sh --attach=none
      '')

      ''
        # Once a day, if $WORKSPACES_HOST_REPO is a real clone, check (in
        # the background, so shell startup is never blocked or slowed by
        # a network call) whether origin/main has moved and nudge the
        # engineer to run `workspaces-host-update` - the same "you're
        # behind upstream" convenience the original repo's chezmoi-based
        # fish greeting provided, minus anything that blocks startup or
        # requires network access to even start a shell.
        if [ -d "$WORKSPACES_HOST_REPO/.git" ]; then
          state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/workspaces-host"
          stamp="$state_dir/last-update-check"
          mkdir -p "$state_dir"
          today=$(date +%Y-%m-%d)
          last=""
          [ -f "$stamp" ] && last=$(cat "$stamp")
          if [ "$today" != "$last" ]; then
            echo "$today" >"$stamp"
            (
              git -C "$WORKSPACES_HOST_REPO" fetch --quiet origin main 2>/dev/null || exit 0
              behind=$(git -C "$WORKSPACES_HOST_REPO" rev-list --count HEAD..origin/main 2>/dev/null)
              if [ -n "$behind" ] && [ "$behind" != "0" ]; then
                echo "workspaces-host-v2: $behind commit(s) behind origin/main - run workspaces-host-update to pick up new features" >&2
              fi
            ) &
            disown
          fi
        fi
      ''

      (lib.mkOrder 2000 ''
        [[ ! ''${BLE_VERSION-} ]] || ble-attach
      '')
    ];
  };

  # bash becomes the interactive shell for this profile without touching
  # /etc/shells or /etc/passwd here (home-manager standalone mode can't
  # manage either on its own) - install.sh does that separately, as a
  # best-effort `chsh` step once bash's own home-manager-pinned binary
  # exists on disk, since a user's login shell isn't itself something
  # Nix ever manages. It's the container/session entrypoint directly in
  # Phase 2's OCI image instead.

  programs.oh-my-posh = {
    enable = true;
    enableBashIntegration = true;
    # The exact theme from strategy-coach/workspaces-host
    # (dot_config/oh-my-posh/coach.omp.json), carried over byte-for-byte so
    # the default prompt styling matches the original repo this project
    # succeeds, not a new placeholder theme. `disable_notice` is merged
    # in here rather than edited into that checked-in file, to keep its
    # byte-for-byte provenance intact.
    #
    # This is `disable_notice`, not `auto_upgrade`: oh-my-posh's own
    # binary here lives in the read-only Nix store, so a self-upgrade
    # would either fail outright or, worse, silently write a new binary
    # somewhere Nix doesn't know about and doesn't track - fighting the
    # exact thing this whole repo exists to guarantee (Constitution
    # Principle I: pinned by lockfile, not resolved against a mutable
    # upstream at runtime). A newer oh-my-posh here means bumping this
    # flake's nixpkgs pin, the same as any other tool - the update
    # notice's CLI toggles (`oh-my-posh enable/disable notice`) are also
    # reported unreliable upstream, so the config-file setting is used
    # directly instead, per oh-my-posh's own FAQ.
    settings = builtins.fromJSON (
      builtins.unsafeDiscardStringContext
        (builtins.readFile ../themes/oh-my-posh/coach.omp.json)
    ) // {
      disable_notice = true;
    };
  };

  # Smarter `cd` (`z`/`zi`, frecency-ranked - see README) and fuzzy
  # history/file search (Ctrl-R, Ctrl-T, Alt-C) - the closest bash
  # equivalents to conveniences fish either had built in or made trivial
  # via a plugin. Both are opt-in *commands* alongside the real `cd`,
  # not replacements for it - predictable for anyone still learning
  # what `cd` actually does, powerful for anyone who wants it.
  programs.zoxide.enable = true;

  programs.fzf = {
    enable = true;
    # fd instead of the default find(1)-based commands: faster, and
    # respects .gitignore by default (skips node_modules, build
    # artifacts, etc. that nobody wants in a fuzzy file search).
    defaultCommand = "fd --type f --hidden --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --exclude .git";
  };
}
