{ lib, ... }:

{
  # Identity is intentionally set here rather than left to a manually-edited
  # ~/.gitconfig: `mkDefault` so ~/.config/workspaces-host/local.nix (see
  # README's "Updating your Git identity, and other secrets, from the
  # CLI") can override it with a plain `programs.git.userName = "...";`
  # and no Nix "conflicting definition" error - never edit the values
  # below directly, that's a core-repo file every `workspaces-host-update`
  # pull touches.
  programs.git = {
    enable = true;

    userName = lib.mkDefault "Workspace Engineer";
    userEmail = lib.mkDefault "workspace@example.invalid";

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
