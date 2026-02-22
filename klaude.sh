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

# Build volume mounts
VOLUMES="-v $(pwd):/workspace"
VOLUMES="$VOLUMES -v $HOME/.claude:/home/node/.claude"

# Mount git config if it exists
[ -f "$HOME/.gitconfig" ] && VOLUMES="$VOLUMES -v $HOME/.gitconfig:/home/node/.gitconfig:ro"

# Mount SSH keys if they exist (for git push/pull)
[ -d "$HOME/.ssh" ] && VOLUMES="$VOLUMES -v $HOME/.ssh:/home/node/.ssh:ro"

exec docker run $DOCKER_FLAGS \
  --cap-add=NET_ADMIN \
  $VOLUMES \
  -w /workspace \
  "$IMAGE" \
  "$@"
