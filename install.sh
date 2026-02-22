#!/bin/bash
# klaude installer — clone, build, alias
set -e

REPO="https://github.com/farmer1st/klaude.git"
DEFAULT_DIR="$HOME/Documents/Dev/farmer1st/github/klaude"
IMAGE="klaude"

INSTALL_DIR="${1:-$DEFAULT_DIR}"

echo "[klaude] Installing to $INSTALL_DIR"

# Clone or pull
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "[klaude] Repo exists, pulling latest..."
  cd "$INSTALL_DIR" && git pull
else
  echo "[klaude] Cloning repo..."
  git clone "$REPO" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Build Docker image
echo "[klaude] Building Docker image..."
docker build -t "$IMAGE" .

# Make wrapper executable
chmod +x klaude.sh

# Detect shell rc file
if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
  RC_FILE="$HOME/.zshrc"
else
  RC_FILE="$HOME/.bashrc"
fi

# Add aliases if not already present
if ! grep -q 'alias klaude=' "$RC_FILE" 2>/dev/null; then
  echo "" >> "$RC_FILE"
  echo "# klaude — Dockerized Claude Code" >> "$RC_FILE"
  echo "alias klaude=\"$INSTALL_DIR/klaude.sh\"" >> "$RC_FILE"
  echo "alias klaude-upgrade=\"cd $INSTALL_DIR && git pull && docker build --no-cache -t $IMAGE .\"" >> "$RC_FILE"
  echo "[klaude] Aliases added to $RC_FILE"
else
  echo "[klaude] Aliases already exist in $RC_FILE"
fi

echo ""
echo "[klaude] Done! Restart your shell or run: source $RC_FILE"
echo ""
echo "Usage:"
echo "  klaude                          # interactive session"
echo "  klaude -p \"fix lint errors\"     # headless mode"
echo "  klaude-upgrade                  # pull latest + rebuild image"
