# agent-sandbox

Run Claude Code in an isolated Docker container with full permissions but no access to your host filesystem beyond what's explicitly mounted.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/jfxg/agent-sandbox/main/install.sh | bash
```

This downloads the scripts to `~/bin/`, the Docker files to `~/.agent-sandbox/docker/`, and builds the image.

**Dependencies:** Docker, `jq` (`brew install jq`), and a working [Claude Code](https://claude.ai/code) login on your host.

<details>
<summary>Manual install</summary>

```bash
git clone https://github.com/jfxg/agent-sandbox.git
cd agent-sandbox
cp bin/agent bin/agent-build ~/bin/
chmod +x ~/bin/agent ~/bin/agent-build
cp -r docker/ ~/.agent-sandbox/docker/
cp VERSION ~/.agent-sandbox/VERSION
agent-build
```

</details>

## Usage

The primary use is pointing the agent at a repo and giving it a task:

```bash
# Mount a local repo and give the agent a task
agent --repo ~/code/myproject "refactor the auth module"

# Clone a GitHub repo and start an interactive session
agent --repo owner/repo

# Clone a specific branch
agent --repo owner/repo --branch feature/my-branch
```

Label sessions to make them easier to identify later:

```bash
agent --repo ~/code/myproject --name auth-refactor "refactor the auth module"
```

Resume a previous session to continue where you left off (workspace and conversation history intact):

```bash
agent ls                              # find the session ID
agent --resume 20240315-143022-myproject-auth-refactor
```

Drop into a shell inside the same container environment instead of launching Claude directly — useful for debugging, or run `claude` manually from within the shell:

```bash
agent --repo ~/code/myproject --shell
```

### Session management

```bash
agent ls                     # list all sessions, newest first
agent rm <session-id>        # remove a session and its workspace
agent clean                  # remove unnamed sessions older than 7 days
agent clean --days 0         # remove all unnamed sessions
```

### Ollama backend

```bash
agent --repo ~/code/myproject --ollama http://192.168.1.50:11434
# or set OLLAMA_BASE_URL and just pass --ollama
```

### Rebuild the image

```bash
agent-build            # normal build
agent-build --no-cache # force full layer rebuild
```

> **macOS + Docker Desktop:** Docker Desktop's containerd image store resets frequently — typically after sleep or the screen locking — which removes the sandbox image. `agent` detects this and rebuilds automatically before starting your session.

## Session storage

Sessions persist at `~/.agent-sandbox/sessions/<id>/` after the container exits.

```
~/.agent-sandbox/
  docker/           ← Dockerfile + entrypoint
  sessions/
    20240315-143022-myproject-auth-refactor/
      session.json  ← session metadata
      workspace/    ← cloned repo lives here
```

For mounted local repos (`--repo ~/path/to/repo`), the workspace is your original directory and is never deleted by `agent rm` or `agent clean`.

## Updates

`agent` checks the current version against GitHub on every run and prints a warning if you're out of date:

```
==> Update available: agent-sandbox 0.2.0 (you have 0.1.0)
    Run: cd <agent-sandbox repo> && git pull && ./install.sh
```

To update, re-run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/jfxg/agent-sandbox/main/install.sh | bash
```

Or if you cloned the repo:

```bash
git pull && ./install.sh
```

The check is non-blocking and fails silently if you're offline.

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AGENT_SANDBOX_DIR` | `~/.agent-sandbox/docker` | Where `agent-build` looks for the Dockerfile |
| `OLLAMA_BASE_URL` | — | Default Ollama URL for `--ollama` |
| `DOCKER_CONTEXT` | system default | Docker context (e.g. `desktop-linux` for Docker Desktop on Mac) |
