#!/bin/bash
# guard-git.sh — wraps git to block irreversible remote operations
# Placed at /usr/local/bin/git (takes priority over /usr/bin/git in PATH)

REAL_GIT=/usr/bin/git
ARGS="$*"

# --- Block destructive remote operations ---

# git push --force (any variant)
if echo "$ARGS" | grep -qE 'push\b.*(-f|--force|--force-with-lease)'; then
  echo "[klaude] BLOCKED: 'git push --force' rewrites remote history." >&2
  echo "[klaude] This safeguard cannot be overridden inside klaude." >&2
  exit 1
fi

# git push --delete on main/master
if echo "$ARGS" | grep -qE 'push\b.*(--delete|-d)\b.*(main|master)\b'; then
  echo "[klaude] BLOCKED: deleting main/master branch from remote." >&2
  exit 1
fi

# git reset --hard (destroys uncommitted work)
if echo "$ARGS" | grep -qE 'reset\b.*--hard'; then
  echo "[klaude] BLOCKED: 'git reset --hard' destroys uncommitted work." >&2
  exit 1
fi

# git clean -f (deletes untracked files permanently)
if echo "$ARGS" | grep -qE 'clean\b.*-[a-zA-Z]*f'; then
  echo "[klaude] BLOCKED: 'git clean -f' permanently deletes untracked files." >&2
  exit 1
fi

# All other git commands pass through
exec "$REAL_GIT" "$@"
