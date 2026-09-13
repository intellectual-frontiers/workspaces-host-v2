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
  # configured key into every interactive shell, each known CLI gets a
  # bash function of the same name that:
  #   1. `local`-declares each of its known credential variable names -
  #      at the *function's* scope, not inside the `for` loop below (a
  #      `local` declared inside a `for`/`if`/`while` block in bash is
  #      still function-scoped, unlike fish's block-scoped `-l`/`-lx` -
  #      verified for real, not assumed, since fish's own equivalent
  #      here had a genuine scoping bug caught the same way),
  #   2. looks for a decrypted secret file matching one of those names,
  #      and if found, `export`s it - which updates the already-`local`
  #      variable in place rather than creating a new global, since
  #      bash resolves a dynamically-constructed `export "$var=..."`
  #      assignment by name exactly the same as a literal one - and
  #   3. calls `command <name> "$@"` (bypassing this very function) to
  #      run the real binary, however it was installed (`npm install -g`
  #      or a Nix package).
  # Once the function returns, every one of these variables - local to
  # it - is gone; nothing leaks into the interactive shell that called
  # it. If no matching secret is configured, this is a transparent
  # no-op pass-through - a CLI's own browser-based `login` flow (or
  # `gh`/`glab`'s own stored auth, or an already-set env var from
  # outside) works exactly as if this wrapper didn't exist.
  wrapCli = name: varNames:
    let
      predeclare = lib.concatMapStringsSep "\n" (v: "    local ${v}") varNames;
      varList = lib.concatStringsSep " " varNames;
    in
    ''
      ${name}() {
    ${predeclare}
        for var in ${varList}; do
          f="${secretsEnvDir}/$var"
          if [ -f "$f" ]; then
            export "$var=$(cat "$f")"
          fi
        done
        command ${name} "$@"
      }
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
  programs.bash.initExtra = lib.concatStrings (map
    ({ name, vars }: wrapCli name vars)
    [
      { name = "claude"; vars = [ "ANTHROPIC_API_KEY" ]; }
      { name = "codex"; vars = [ "OPENAI_API_KEY" ]; }
      { name = "gemini"; vars = [ "GEMINI_API_KEY" "GOOGLE_API_KEY" ]; }
      { name = "aider"; vars = [ "ANTHROPIC_API_KEY" "OPENAI_API_KEY" "GEMINI_API_KEY" "GOOGLE_API_KEY" ]; }
      { name = "gh"; vars = [ "GITHUB_TOKEN" "GH_TOKEN" ]; }
      { name = "glab"; vars = [ "GITLAB_TOKEN" ]; }
    ]);
}
