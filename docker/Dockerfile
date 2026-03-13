FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ── System packages ───────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    ripgrep \
    fd-find \
    jq \
    less \
    build-essential \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js 22 ────────────────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── Java 21 ───────────────────────────────────────────────────────────────────
# Ubuntu 24.04 ships OpenJDK 21 natively — no third-party repo needed
RUN apt-get update && apt-get install -y --no-install-recommends openjdk-21-jdk \
    && rm -rf /var/lib/apt/lists/*

# ── GitHub CLI ────────────────────────────────────────────────────────────────
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# ── fd alias (Ubuntu names the binary fdfind) ─────────────────────────────────
RUN ln -s $(which fdfind) /usr/local/bin/fd

# ── Entrypoint script (runs as root before user switch so it's in a stable path)
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

# ── Dedicated agent user ───────────────────────────────────────────────────────
RUN useradd -m -s /bin/zsh agent \
    && mkdir -p /workspace /home/agent/.local/bin \
    && chown -R agent:agent /workspace /home/agent

USER agent

# Ensure ~/.local/bin is in PATH for all processes (not just interactive shells)
ENV PATH="/home/agent/.local/bin:$PATH"

# ── Claude Code (native installer) ────────────────────────────────────────────
RUN curl -fsSL https://claude.ai/install.sh | bash

# ── oh-my-zsh ─────────────────────────────────────────────────────────────────
# Install unattended — the host's .zshrc will be mounted over the generated one
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["zsh"]
