# Feature Specification: PostgreSQL Credential Tooling

**Feature Branch**: `013-postgres-credential-tooling`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "Implement #4: PostgreSQL credential tooling (.pgpass, .psqlrc, pgpass CLI) - identified as missing in the gap analysis against strategy-coach/workspaces-host."

## Background

The original repo templated `~/.pgpass` (`create_private_dot_pgpass`) and
`~/.psqlrc` (`dot_psqlrc.tmpl`), and globally installed a `pgpass` CLI
(`netspective-labs/sql-aide`'s Deno `pgpass.ts`) for looking up connections
by id (env vars, a ready `psql` command, or a connection URL). This
rewrite's secrets spec (004) claimed to replace this, but nothing
concretely reproduced it - confirmed as a real, standalone gap.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A usable `psql` out of the box (Priority: P2)

An engineer running `psql` gets the original repo's colored prompt, sane
history/pager settings, and admin query shortcuts (`:settings`, `:locks`,
`:dbsize`, etc.) without configuring anything themselves.

**Independent Test**: Activate a profile; confirm `~/.psqlrc` exists with
the expected `\set`/`\pset` directives; run `psql` against any reachable
Postgres server (or `psql --version`) to confirm the file parses without
error.

---

### User Story 2 - Declare connections once, look them up by id (Priority: P1)

An engineer adds a connection to `~/.pgpass` once (host/port/db/user/pass
plus a small id/description/boundary descriptor comment) and then
retrieves it - as exported env vars, a ready-to-run `psql` command, or a
`postgres://` URL - by that id from anywhere, without re-typing connection
details or `grep`-ing the raw file.

**Why priority P1**: This is the actual capability gap - `.psqlrc` is a
nice-to-have, but `pgpass`-by-id lookup is the thing the original repo's
own docs call out as its main convenience (`.envrc` integration,
`psql \`pgpass psql-fmt ...\``, etc.).

**Independent Test**: Add a connection descriptor + line to `~/.pgpass`;
run `pgpass ls`, `pgpass test`, `pgpass env --conn-id=<id>`,
`pgpass url --conn-id=<id>`, and `pgpass psql --conn-id=<id>`; confirm each
produces correct, matching output for that connection.

**Acceptance Scenarios**:

1. **Given** `~/.pgpass` with one descriptor+connection line, **When**
   `pgpass ls` runs, **Then** it prints that connection's id, description,
   and `host:port user@database`.
2. **Given** the same file, **When** `pgpass env --conn-id=<id>` runs,
   **Then** it prints `export <ID>_PGHOST=...` etc. for
   PGHOST/PGPORT/PGDATABASE/PGUSER/PGPASSWORD, matching the connection's
   actual values.
3. **Given** the same file, **When** `pgpass url --conn-id=<id>` runs,
   **Then** it prints `postgres://user:pass@host:port/database`.
4. **Given** a connection line with no preceding descriptor comment,
   **When** `pgpass test` runs, **Then** it reports that specific line as
   an issue and exits non-zero.

---

### Edge Cases

- `~/.pgpass` holds real credentials - home-manager creates it once
  (empty, format-documentation only, mode `600`) on first activation and
  never touches an existing file again, the same category of file as
  `~/workspaces/mgit.json` or `sensitivectl`'s config.
- `~/.psqlrc` has no secrets, so unlike `.pgpass` it's fully declarative
  (`home.file`) and always in sync with the Nix store, like any other
  dotfile in this repo.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `home/postgres.nix` MUST manage `~/.psqlrc` declaratively
  via `home.file`, carrying over the original's prompt/history/pager
  settings and admin query shortcuts unchanged.
- **FR-002**: `home/postgres.nix` MUST create `~/.pgpass` (mode `600`,
  format-documentation only, no real credentials) via `home.activation` on
  first activation, and MUST NOT overwrite an existing `~/.pgpass`.
- **FR-003**: A new `pgpass` package (`pkgs/pgpass`) MUST provide `ls`,
  `test`, `env`, `url`, and `psql` subcommands operating on the id/
  description/boundary comment-header convention already documented in
  the original repo's `.pgpass` template.
- **FR-004**: `pkgs/doctor/doctor` MUST report `pgpass` on PATH and
  whether `~/.pgpass` (with mode 600) and `~/.psqlrc` exist.
- **FR-005**: README.md MUST document the `.pgpass` descriptor format and
  every `pgpass` subcommand with runnable examples.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix build .#homeConfigurations.default.activationPackage`
  succeeds with `pgpass` and `home/postgres.nix` included.
- **SC-002**: A real activation creates `~/.psqlrc` and an empty,
  mode-600 `~/.pgpass`; a second activation leaves an edited `~/.pgpass`
  untouched.
- **SC-003**: Against a real `~/.pgpass` entry, `pgpass ls`/`test`/`env`/
  `url`/`psql` all produce correct output for that connection's id.
- **SC-004**: `nix flake check --all-systems` continues to pass.

## Assumptions

- This ports a deliberate *subset* of `pgpass.ts`'s command surface:
  `ls`, `test`, `env`, `url`, `psql`. Left out: `psql-fmt`/`pgcenter`/
  `pgready` (thin variations on `psql`'s "print a runnable command" idea -
  users can adapt `pgpass psql`'s output for these), `prepare` (arbitrary
  JS `eval` string templating - a shell-native equivalent isn't a like-for-
  like port and the security tradeoff of shell `eval` on top of untrusted
  format strings isn't worth it for a rarely-used convenience), `inspect`/
  `urls-dict-json`/`--json` (structured-output variants; `pgpass ls` and
  `env`/`url`/`psql` cover the common cases). `--conn-id` accepts a single
  regex rather than the original's repeatable `--conn-id` list, and
  descriptor parsing quotes bare JSON5-style object keys with `sed` rather
  than a full JSON5 parser - sufficient for the simple `id`/`description`/
  `boundary` string fields this format actually uses.
- The `.pgpass` bootstrap stub intentionally contains no real credentials
  (only commented-out format documentation, matching the original
  checked-in template's own placeholder example), consistent with
  Constitution Principle III (secrets are a deliberate, separate human
  action, never Nix-store-managed plaintext).
