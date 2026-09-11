{ ... }:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      ll = "ls -lah";
      g = "git";
    };

    interactiveShellInit = ''
      set -g fish_greeting
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
    settings = builtins.fromJSON (
      builtins.unsafeDiscardStringContext
        (builtins.readFile ../themes/oh-my-posh/default.omp.json)
    );
  };
}
