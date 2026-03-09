#!/bin/bash
# entrypoint.sh: Runs before each agent session.
# - Copies host Claude credentials (mounted read-only) to a writable home location
# - Pre-trusts /workspace so Claude doesn't prompt on startup
set -e

# ── Copy host Claude credentials to writable home ─────────────────────────────
# ~/.claude is mounted read-only at /tmp/claude-host so we can copy it here
# and still have a writable config directory for the session.
# We skip the projects/ directory — it contains session history for host paths
# that don't exist inside the container and would just be noise.
if [[ -d /tmp/claude-host ]]; then
    mkdir -p "$HOME/.claude"
    for item in /tmp/claude-host/*; do
        [[ "$(basename "$item")" == "projects" ]] && continue
        cp -rp "$item" "$HOME/.claude/"
    done
fi

if [[ -f /tmp/claude-host.json ]]; then
    cp /tmp/claude-host.json "$HOME/.claude.json"
fi

# Write Keychain OAuth credentials to ~/.claude/.credentials.json.
# On macOS, Claude Code stores auth in Keychain as {"claudeAiOauth": {"accessToken":...,"refreshToken":...}}.
# On Linux, it reads the same JSON structure from ~/.claude/.credentials.json — so we can
# copy the Keychain blob directly. Claude Code will auto-refresh the access token if it's expired.
if [[ -f /tmp/claude-credentials ]]; then
    mkdir -p "$HOME/.claude"
    cp /tmp/claude-credentials "$HOME/.claude/.credentials.json"
fi

# ~/.local/share/claude is used by the native installer for auth storage.
if [[ -d /tmp/claude-local-share ]]; then
    mkdir -p "$HOME/.local/share/claude"
    cp -rp /tmp/claude-local-share/. "$HOME/.local/share/claude/"
fi

# ── Determine working directory ───────────────────────────────────────────────
# When cloning a repo, work inside /workspace/<reponame> so Claude's project
# name matches the repo rather than showing the generic "workspace".
WORK_DIR="/workspace"
if [[ -n "${CLONE_REPO:-}" ]]; then
    WORK_DIR="/workspace/${CLONE_REPO##*/}"
fi

# ── Clone GitHub repo if requested ────────────────────────────────────────────
# CLONE_REPO is set by the agent script when --repo owner/repo is passed.
# We use gh repo clone so it picks up the host's gh auth automatically.
if [[ -n "${CLONE_REPO:-}" ]] && [[ ! -d "$WORK_DIR/.git" ]]; then
    BRANCH_ARGS=()
    [[ -n "${CLONE_BRANCH:-}" ]] && BRANCH_ARGS+=(-- --branch "$CLONE_BRANCH")
    gh repo clone "$CLONE_REPO" "$WORK_DIR" "${BRANCH_ARGS[@]}"
fi

# ── Pre-trust the working directory ───────────────────────────────────────────
# Claude Code stores workspace trust in ~/.claude.json under .projects["<path>"].
# Pre-setting hasTrustDialogAccepted avoids the interactive trust prompt on startup.
if [[ -f "$HOME/.claude.json" ]]; then
    jq --arg dir "$WORK_DIR" '.projects[$dir].hasTrustDialogAccepted = true' "$HOME/.claude.json" \
        > /tmp/.claude.json.tmp && mv /tmp/.claude.json.tmp "$HOME/.claude.json"
fi

# ── Skip dangerous-mode permission prompt ─────────────────────────────────────
# Claude Code stores this acknowledgement in ~/.claude/settings.json.
# Pre-setting it avoids the one-time confirmation when using --dangerously-skip-permissions.
SETTINGS="$HOME/.claude/settings.json"
mkdir -p "$(dirname "$SETTINGS")"
if [[ -f "$SETTINGS" ]]; then
    jq '.skipDangerousModePermissionPrompt = true' "$SETTINGS" \
        > /tmp/.settings.json.tmp && mv /tmp/.settings.json.tmp "$SETTINGS"
else
    echo '{"skipDangerousModePermissionPrompt": true}' > "$SETTINGS"
fi

# ── Change to working directory ───────────────────────────────────────────────
cd "$WORK_DIR"

exec "$@"
