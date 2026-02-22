#!/bin/bash
set -e

# --- Firewall: default-deny outbound, whitelist specific domains ---

ALLOWED_DOMAINS=(
  # Claude API
  api.anthropic.com
  api.claude.ai
  claude.ai
  # npm
  registry.npmjs.org
  # GitHub
  github.com
  api.github.com
  # Notifications
  ntfy.sh
  # Package registries
  pypi.org
  files.pythonhosted.org
)

setup_firewall() {
  # Flush existing rules
  sudo iptables -F OUTPUT 2>/dev/null || true

  # Allow loopback
  sudo iptables -A OUTPUT -o lo -j ACCEPT

  # Allow established/related connections
  sudo iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

  # Allow DNS (needed to resolve domains)
  sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
  sudo iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

  # Resolve and allow each domain
  for domain in "${ALLOWED_DOMAINS[@]}"; do
    ips=$(dig +short "$domain" 2>/dev/null | grep -E '^[0-9]+\.' || true)
    for ip in $ips; do
      sudo iptables -A OUTPUT -d "$ip" -j ACCEPT
    done
  done

  # Allow private/local networks (for localhost dev servers)
  sudo iptables -A OUTPUT -d 127.0.0.0/8 -j ACCEPT
  sudo iptables -A OUTPUT -d 10.0.0.0/8 -j ACCEPT
  sudo iptables -A OUTPUT -d 172.16.0.0/12 -j ACCEPT
  sudo iptables -A OUTPUT -d 192.168.0.0/16 -j ACCEPT

  # Default deny all other outbound
  sudo iptables -A OUTPUT -j REJECT

  echo "[klaude] Firewall active — outbound restricted to whitelisted domains"
}

# Try to set up firewall (needs NET_ADMIN capability)
if setup_firewall 2>/dev/null; then
  :
else
  echo "[klaude] Warning: firewall setup failed (missing --cap-add=NET_ADMIN). Running without network isolation."
fi

# Run claude with full autonomy
exec claude --dangerously-skip-permissions "$@"
