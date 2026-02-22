FROM node:20-slim

ARG CLAUDE_CODE_VERSION=latest

# Install essentials
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    jq \
    iptables \
    iproute2 \
    dnsutils \
    sudo \
    zsh \
    openssh-client \
    ca-certificates \
    gpg \
  && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list \
  && apt-get update && apt-get install -y --no-install-recommends gh \
  && rm -rf /var/lib/apt/lists/*

# Give node user sudo for iptables (firewall setup)
RUN echo "node ALL=(ALL) NOPASSWD: /usr/sbin/iptables, /usr/sbin/ip6tables" > /etc/sudoers.d/node-iptables

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Install guard scripts — wrap git and gh to block irreversible operations
# /usr/local/bin takes priority over /usr/bin in PATH
COPY guard-git.sh /usr/local/bin/git
COPY guard-gh.sh /usr/local/bin/gh
RUN chmod +x /usr/local/bin/git /usr/local/bin/gh

USER node
WORKDIR /workspace

ENTRYPOINT ["entrypoint.sh"]
