{ config, lib, pkgs, ... }:

let
  # Where a credential ends up as a plain file named after its own
  # variable - written directly by `workspaces-host-update` (see
  # README's "Setting up your credentials" section) for the common case,
  # or by home/secrets.nix's optional sops-based `path = "env/VARNAME"`
  # mechanism for anyone who specifically wants field-level encryption
  # at rest. Both feed the same directory; this module doesn't care
  # which one wrote a given file, only that it might be there.
  secretsEnvDir = "${config.xdg.stateHome}/workspaces-host/secrets/env";

  # Constitution Principle III ("secrets never touch the agent's shell
  # unscoped") is explicit and non-negotiable: a credential MUST be
  # resolved "at the point of use," never as an ambient variable
  # available to the whole shell session. So instead of exporting a
  # configured key into every interactive shell (which is what an
  # earlier version of this file did, and which a Nix-conformance/
  # constitution audit correctly flagged as a real violation), each
  # known AI CLI gets a fish function of the same name that:
  #   1. looks for a decrypted secret file matching one of its known
  #      credential variable names,
  #   2. if found, sets it with `set -lx` - fish's function-scoped,
  #      exported variable, visible to this one invocation's child
  #      process and automatically gone once the function returns, never
  #      leaking into the parent shell - and
  #   3. calls `command <name> $argv` (bypassing this very function) to
  #      run the real binary, however it was installed (`npm install -g`
  #      or a Nix package).
  # If no matching secret is configured, this is a transparent no-op
  # pass-through - a CLI's own browser-based `login` flow (or `gh`/
  # `glab`'s own stored auth, or an already-set env var from outside)
  # works exactly as if this wrapper didn't exist.
  wrapCli = name: varNames:
    let
      # Fish scopes `set -l`/`-lx` to the *innermost enclosing block* -
      # a `for` loop is its own block, so a variable set with `-lx`
      # inside one is destroyed the moment the loop ends, before
      # `command <name>` below ever runs (verified: an earlier version
      # of this wrapper set the variable successfully but the spawned
      # process never saw it - a real, empirically-confirmed fish
      # scoping bug, not a hypothetical one). Pre-declaring each
      # candidate variable at the function's own top-level scope first,
      # then assigning to it with a bare `set` (no `-l`) inside the
      # loop, makes fish update that already-declared function-scoped
      # variable in place instead of shadowing it inside the loop's
      # block - so it's still alive, and still exported, when `command`
      # runs, and still gone the moment this function returns.
      predeclare = lib.concatMapStringsSep "\n" (v: "set -lx ${v} \"\"") varNames;
    in
    ''
      ${predeclare}
      for var in ${lib.concatStringsSep " " varNames}
        set -l f "${secretsEnvDir}/$var"
        if test -f "$f"
          set $var (cat "$f")
        end
      end
      command ${name} $argv
    '';
in
{
  # AI-assisted CLI tooling, so an AI harness can help configure this
  # sandbox itself right after install (edit the credentials file,
  # explore a `doctor` WARN, etc.), not just help with application code.
  #
  # `aider-chat` is genuinely packaged in this flake's pinned nixpkgs and
  # provider-agnostic (works with Claude, GPT, Gemini, ... via whichever
  # API key you export), so it's installed directly here, the same as
  # every other tool in this repo.
  #
  # Claude Code (`@anthropic-ai/claude-code`), OpenAI's Codex CLI
  # (`@openai/codex`), and Google's Gemini CLI (`@google/gemini-cli`)
  # are NOT Nix-packaged here on purpose: they ship near-weekly releases,
  # and hand-vendoring each one as a `buildNpmPackage` derivation would
  # mean either pinning to a stale version indefinitely or re-deriving a
  # new npm hash on every release - a maintenance burden this repo isn't
  # taking on for tools whose whole value is being current. `nodejs`
  # (their shared runtime) is provisioned here instead, so installing the
  # actual CLI is just the one `npm install -g` command upstream already
  # documents - see README's "Setting up AI harness credentials" section
  # for the exact commands and, more importantly, the safe way to give
  # each one its API key without ever putting it in a tracked file.
  home.packages = [
    pkgs.nodejs
    pkgs.aider-chat
  ];

  # `gh`/`glab` (home/tools.nix) get the exact same treatment as the AI
  # CLIs above: a GITHUB_TOKEN/GITLAB_TOKEN from the credentials file is
  # scoped to just that one invocation, never the whole shell - the same
  # mechanism, just applied to two more tools that read a token the same
  # way an AI CLI reads an API key.
  programs.fish.functions = {
    claude = wrapCli "claude" [ "ANTHROPIC_API_KEY" ];
    codex = wrapCli "codex" [ "OPENAI_API_KEY" ];
    gemini = wrapCli "gemini" [ "GEMINI_API_KEY" "GOOGLE_API_KEY" ];
    aider = wrapCli "aider" [ "ANTHROPIC_API_KEY" "OPENAI_API_KEY" "GEMINI_API_KEY" "GOOGLE_API_KEY" ];
    gh = wrapCli "gh" [ "GITHUB_TOKEN" "GH_TOKEN" ];
    glab = wrapCli "glab" [ "GITLAB_TOKEN" ];
  };
}
