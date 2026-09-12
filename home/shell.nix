{ config, ... }:

{
  # Where workspaces-host-v2 itself is cloned - used by
  # `workspaces-host-update` and the daily upstream-check nudge below.
  # Override this (e.g. in a fork, or via `home.sessionVariables` in a
  # wrapping module) if you cloned it somewhere other than
  # ~/workspaces-host-v2 (see README's install steps).
  home.sessionVariables.WORKSPACES_HOST_REPO = "${config.home.homeDirectory}/workspaces-host-v2";

  programs.fish = {
    enable = true;

    shellAliases = {
      ll = "ls -lah";
      g = "git";
    };

    interactiveShellInit = ''
      set -g fish_greeting

      # Once a day, if $WORKSPACES_HOST_REPO is a real clone, check (in
      # the background, so shell startup is never blocked or slowed by a
      # network call) whether origin/main has moved and nudge the
      # engineer to run `workspaces-host-update` - the same "you're behind
      # upstream" convenience the original repo's chezmoi-based fish
      # greeting provided, minus anything that blocks startup or requires
      # network access to even start a shell.
      if test -d "$WORKSPACES_HOST_REPO/.git"
        set -l state_dir (test -n "$XDG_STATE_HOME"; and echo $XDG_STATE_HOME; or echo "$HOME/.local/state")/workspaces-host
        set -l stamp "$state_dir/last-update-check"
        mkdir -p "$state_dir"
        set -l today (date +%Y-%m-%d)
        set -l last ""
        if test -f "$stamp"
          set last (cat "$stamp")
        end
        if test "$today" != "$last"
          echo "$today" >"$stamp"
          fish -c '
            git -C "$WORKSPACES_HOST_REPO" fetch --quiet origin main 2>/dev/null
            or exit 0
            set behind (git -C "$WORKSPACES_HOST_REPO" rev-list --count HEAD..origin/main 2>/dev/null)
            if test -n "$behind" -a "$behind" != "0"
              echo "workspaces-host-v2: $behind commit(s) behind origin/main - run workspaces-host-update to pick up new features" >&2
            end
          ' &
          disown
        end
      end
    '';
  };

  # Fish becomes the interactive shell for this profile without touching
  # /etc/shells or /etc/passwd (which home-manager standalone mode cannot
  # manage on its own) - engineers chsh into it themselves per
  # quickstart.md, or it's set as the container/session entrypoint in
  # Phase 2.

  programs.oh-my-posh = {
    enable = true;
    enableFishIntegration = true;
    # The exact theme from strategy-coach/workspaces-host
    # (dot_config/oh-my-posh/coach.omp.json), carried over byte-for-byte so
    # the default prompt styling matches the original repo this project
    # succeeds, not a new placeholder theme.
    settings = builtins.fromJSON (
      builtins.unsafeDiscardStringContext
        (builtins.readFile ../themes/oh-my-posh/coach.omp.json)
    );
  };
}
