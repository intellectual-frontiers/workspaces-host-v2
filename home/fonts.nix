{ pkgs, ... }:

{
  # The coach.omp.json prompt theme (home/shell.nix) uses Nerd Font
  # private-use-area glyphs (branch icon, OS icon, folder, exit-status,
  # clock, language-version icons, ...). Installing the font file here
  # makes it available to pick; it does NOT make any terminal emulator use
  # it automatically - that's a per-terminal-app setting only a human can
  # make (there is no single "the terminal" home-manager can configure
  # across WSL/Windows Terminal, GNOME Terminal, iTerm2, etc.) - see
  # README.md's "Nerd Font" section for the actual steps per environment.
  fonts.fontconfig.enable = true;

  home.packages = [
    (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
}
