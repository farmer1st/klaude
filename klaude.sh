#!/bin/bash
# klaude — run Claude Code in a Docker container with full autonomy + network isolation
# Usage: klaude [claude args...]
# Examples:
#   klaude                          # interactive session
#   klaude -p "fix lint errors"     # headless/print mode
#   cat file.ts | klaude -p "explain this"  # pipe mode

IMAGE="klaude"

# Check Docker is running
if ! docker info >/dev/null 2>&1; then
  echo "[klaude] Docker is not running. Start Docker Desktop first." >&2
  exit 1
fi

# Check image exists
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "[klaude] Image '$IMAGE' not found. Build it first:" >&2
  echo "  cd $(dirname "$0") && docker build -t $IMAGE ." >&2
  exit 1
fi

# Detect TTY for interactive vs pipe mode
DOCKER_FLAGS="--rm -i"
if [ -t 0 ] && [ -t 1 ]; then
  DOCKER_FLAGS="--rm -it"
fi

# --- Staging area ---
# Docker Desktop on macOS blocks mounting dotfiles/dotfolders from $HOME directly.
# We stage everything into a tmp dir that Docker can access.
STAGE_DIR="/tmp/klaude-stage"
mkdir -p "$STAGE_DIR"

# Stage .claude directory (settings, memory, projects)
rsync -a --delete "$HOME/.claude/" "$STAGE_DIR/dot-claude/" 2>/dev/null || cp -R "$HOME/.claude/." "$STAGE_DIR/dot-claude/"

# Stage .claude.json (auth config)
[ -f "$HOME/.claude.json" ] && cp "$HOME/.claude.json" "$STAGE_DIR/dot-claude.json"

# Extract OAuth token from macOS Keychain and inject as env var
CLAUDE_CREDENTIALS=""
if command -v security >/dev/null 2>&1; then
  CLAUDE_CREDENTIALS=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || true)
fi

# Build volume mounts
VOLUMES="-v $(pwd):/workspace"
VOLUMES="$VOLUMES -v $STAGE_DIR/dot-claude:/home/node/.claude"
[ -f "$STAGE_DIR/dot-claude.json" ] && VOLUMES="$VOLUMES -v $STAGE_DIR/dot-claude.json:/home/node/.claude.json"

# Mount git config if it exists
[ -f "$HOME/.gitconfig" ] && VOLUMES="$VOLUMES -v $HOME/.gitconfig:/home/node/.gitconfig:ro"

# Mount SSH keys if they exist (for git push/pull)
[ -d "$HOME/.ssh" ] && VOLUMES="$VOLUMES -v $HOME/.ssh:/home/node/.ssh:ro"

# Build env vars
ENV_VARS=""
[ -n "$CLAUDE_CREDENTIALS" ] && ENV_VARS="-e CLAUDE_CREDENTIALS=$CLAUDE_CREDENTIALS"

docker run $DOCKER_FLAGS \
  --cap-add=NET_ADMIN \
  $VOLUMES \
  $ENV_VARS \
  -w /workspace \
  "$IMAGE" \
  "$@"

EXIT_CODE=$?

# Sync back any changes (settings, memory files updated during session)
rsync -a --delete "$STAGE_DIR/dot-claude/" "$HOME/.claude/" 2>/dev/null || cp -R "$STAGE_DIR/dot-claude/." "$HOME/.claude/"
[ -f "$STAGE_DIR/dot-claude.json" ] && cp "$STAGE_DIR/dot-claude.json" "$HOME/.claude.json"

exit $EXIT_CODE
