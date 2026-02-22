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
  && rm -rf /var/lib/apt/lists/*

# Give node user sudo for iptables (firewall setup)
RUN echo "node ALL=(ALL) NOPASSWD: /usr/sbin/iptables, /usr/sbin/ip6tables" > /etc/sudoers.d/node-iptables

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER node
WORKDIR /workspace

ENTRYPOINT ["entrypoint.sh"]
