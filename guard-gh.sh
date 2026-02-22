#!/bin/bash
# guard-gh.sh — wraps gh CLI to block irreversible GitHub operations
# Placed at /usr/local/bin/gh (takes priority over any other gh in PATH)

REAL_GH=/usr/bin/gh

ARGS="$*"

# --- Block destructive GitHub operations ---

# gh repo delete
if echo "$ARGS" | grep -qE '^repo\s+delete'; then
  echo "[klaude] BLOCKED: 'gh repo delete' is irreversible." >&2
  echo "[klaude] This safeguard cannot be overridden inside klaude." >&2
  exit 1
fi

# gh release delete
if echo "$ARGS" | grep -qE '^release\s+delete'; then
  echo "[klaude] BLOCKED: 'gh release delete' is irreversible." >&2
  exit 1
fi

# gh api DELETE on repos (deleting repos, branches, etc via API)
if echo "$ARGS" | grep -qE '^api\b.*-X\s*DELETE'; then
  echo "[klaude] BLOCKED: destructive 'gh api DELETE' call." >&2
  exit 1
fi

# All other gh commands pass through
exec "$REAL_GH" "$@"
