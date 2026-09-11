{ ... }:

{
  # Identity is intentionally set here rather than left to a manually-edited
  # ~/.gitconfig: fork this module (or override home.username/git identity
  # via a wrapping module) per engineer/profile. See
  # specs/001-core-flake-home-manager/quickstart.md for the override steps.
  programs.git = {
    enable = true;

    userName = "Workspace Engineer";
    userEmail = "workspace@example.invalid";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;
      fetch.prune = true;
      core.editor = "vim";
    };

    aliases = {
      st = "status -sb";
      co = "checkout";
      br = "branch";
      ci = "commit";
      lg = "log --oneline --graph --decorate";
      last = "log -1 HEAD";
    };
  };
}
