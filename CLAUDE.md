# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Does

`agent-sandbox` runs Claude Code in isolated Docker containers. It provides session management, credential bridging from the macOS host, and support for both Anthropic and Ollama backends.

## Commands

There is no package manager or build system. The project consists of bash scripts.

**Build the Docker image:**
```bash
agent-build              # Normal build
agent-build --no-cache   # Force full rebuild
```

**Install/update locally:**
```bash
./install.sh
```

**Run the agent:**
```bash
agent --repo ~/myproject          # Mount local repo
agent --repo owner/name           # Clone GitHub repo
agent ls                          # List sessions
agent --resume <session-id>       # Resume a session
agent --shell --resume <id>       # Open shell in existing session
```

## Architecture

The project is four files:

- **`bin/agent`** — Main CLI orchestrator (~430 lines of bash). Handles all argument parsing, preflight checks, credential extraction, session management, and `docker run` construction.
- **`bin/agent-build`** — Thin wrapper around `docker build`.
- **`docker/Dockerfile`** — Image based on `node:22-slim`. Installs system packages, GitHub CLI, Claude Code (via npm), and creates an unprivileged `agent` user with oh-my-zsh.
- **`docker/entrypoint.sh`** — Runs at container start as root before dropping to `agent` user. Copies credentials, clones repos, and pre-trusts the workspace to skip interactive prompts.

### Session Lifecycle

1. `agent` creates a session directory at `~/.agent-sandbox/sessions/<YYYYMMDD-HHMMSS-label>/`
2. A `session.json` stores metadata (workspace path, managed vs mounted, clone info)
3. Container runs with `--rm` (ephemeral), but workspace and `session.json` persist
4. Sessions are resumed by re-mounting the same workspace directory

### Credential Flow (macOS → Container)

- **Claude auth**: OAuth token extracted from macOS Keychain; `~/.claude/` mounted read-only at `/tmp/claude-host`; `entrypoint.sh` copies it into the container's home
- **GitHub auth**: Token extracted via `gh auth token`; passed as `GH_TOKEN` env var
- **Git identity**: `~/.gitconfig` mounted read-only

### Backend Routing

- **Anthropic** (default): Sets `ANTHROPIC_API_KEY` from Keychain token
- **Ollama**: Sets `ANTHROPIC_BASE_URL` to the Ollama endpoint and a dummy API key

### Key Environment Variables

| Variable | Purpose |
|----------|---------|
| `AGENT_SANDBOX_DIR` | Path where Dockerfile lives (default: `~/.agent-sandbox/docker`) |
| `OLLAMA_BASE_URL` | Default Ollama endpoint for `--ollama` flag |
| `DOCKER_CONTEXT` | Docker context name override |

## Development Notes

- All logic lives in bash scripts — no linting or test infrastructure exists.
- The `install.sh` script copies `bin/agent` and `bin/agent-build` to `~/bin/` and docker files to `~/.agent-sandbox/docker/`. After editing scripts locally, re-run `./install.sh` to apply changes, then `agent-build` if the Dockerfile changed.
- `entrypoint.sh` runs as root inside the container before `su agent` — keep it minimal and side-effect-free on the host.

## Versioning

The version is stored in the `VERSION` file at the repo root (e.g. `0.1.0`). The `agent` script curls this file from GitHub on each run and warns the user if their local version is out of date.

**When to bump the version:**
- Any change to `bin/agent` or `bin/agent-build` (user-facing behaviour change, new flag, bug fix)
- Any change to `docker/Dockerfile` or `docker/entrypoint.sh` that requires a rebuild
- Changes to `install.sh`
- No need to bump for README, CLAUDE.md, or comment-only changes

**How to bump:**
1. Edit `VERSION` with the new version string (use [semver](https://semver.org/): `MAJOR.MINOR.PATCH`)
   - Patch: bug fixes, small tweaks
   - Minor: new flags or features, backward-compatible
   - Major: breaking changes to CLI interface or session format
2. Commit it alongside the change that warranted the bump — not as a separate commit
