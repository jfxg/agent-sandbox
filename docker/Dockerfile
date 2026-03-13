FROM node:22-slim

# ── System packages ───────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    gnupg \
    python3 \
    python3-pip \
    ripgrep \
    fd-find \
    jq \
    less \
    build-essential \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# ── Java 21 (Eclipse Temurin) ─────────────────────────────────────────────────
RUN curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public \
        | gpg --dearmor -o /usr/share/keyrings/adoptium.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(. /etc/os-release && echo "$VERSION_CODENAME") main" \
        > /etc/apt/sources.list.d/adoptium.list \
    && apt-get update && apt-get install -y --no-install-recommends temurin-21-jdk \
    && rm -rf /var/lib/apt/lists/*

# ── GitHub CLI ────────────────────────────────────────────────────────────────
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# ── fd alias (Debian names the binary fdfind) ─────────────────────────────────
RUN ln -s $(which fdfind) /usr/local/bin/fd

# ── Claude Code ───────────────────────────────────────────────────────────────
# Install via npm as root — the package is a Node.js script, so it runs on any
# architecture without a native binary. The native installer downloads a
# platform-specific binary that mismatches the container arch under Docker Desktop.
RUN npm install -g @anthropic-ai/claude-code

# ── Entrypoint script (runs as root before user switch so it's in a stable path)
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

# ── Dedicated agent user ───────────────────────────────────────────────────────
# Symlink claude into ~/.local/bin so PATH is consistent whether or not the user
# later runs `claude install` to switch to the native binary inside a live session.
RUN useradd -m -s /bin/zsh agent \
    && mkdir -p /workspace /home/agent/.local/bin \
    && ln -s /usr/local/bin/claude /home/agent/.local/bin/claude \
    && chown -R agent:agent /workspace /home/agent

USER agent

# Ensure ~/.local/bin is in PATH for all processes (not just interactive shells)
ENV PATH="/home/agent/.local/bin:$PATH"

# ── oh-my-zsh ─────────────────────────────────────────────────────────────────
# Install unattended — the host's .zshrc will be mounted over the generated one
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["zsh"]
