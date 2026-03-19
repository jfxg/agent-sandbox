#!/usr/bin/env bash
set -euo pipefail

REPO="jfxg/agent-sandbox"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

BIN_DIR="${HOME}/bin"
SANDBOX_DIR="${HOME}/.agent-sandbox"
DOCKER_DIR="${SANDBOX_DIR}/docker"

info()    { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
success() { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn()    { printf '\033[1;33m!\033[0m %s\n' "$*"; }
die()     { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

# Check dependencies
for cmd in curl docker jq; do
    command -v "$cmd" &>/dev/null || die "'$cmd' is required but not installed."
done

info "Installing agent-sandbox..."

# Create directories
mkdir -p "$BIN_DIR" "$SANDBOX_DIR" "$DOCKER_DIR"

# Download bin scripts
info "Downloading scripts to ${BIN_DIR}..."
for script in agent agent-build; do
    curl -fsSL "${RAW}/bin/${script}" -o "${BIN_DIR}/${script}"
    chmod +x "${BIN_DIR}/${script}"
    success "${script}"
done

# Download VERSION to ~/.agent-sandbox so the agent script can compare it
curl -fsSL "${RAW}/VERSION" -o "${SANDBOX_DIR}/VERSION"
success "VERSION"

# Download docker files
info "Downloading Docker files to ${DOCKER_DIR}..."
for file in Dockerfile entrypoint.sh; do
    curl -fsSL "${RAW}/docker/${file}" -o "${DOCKER_DIR}/${file}"
    success "${file}"
done

# Check PATH
if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]]; then
    warn "${BIN_DIR} is not in your PATH."
    echo "    Add this to your shell config (~/.zshrc or ~/.bashrc):"
    echo "    export PATH=\"\$HOME/bin:\$PATH\""
fi

echo ""
info "Building Docker image (this may take a minute)..."
"${BIN_DIR}/agent-build"

echo ""
success "Installation complete! Run 'agent --help' to get started."
