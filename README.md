# klaude

Dockerized Claude Code with full autonomy and network-isolated security.

Type `klaude` in any directory — get a sandboxed Claude session with `--dangerously-skip-permissions` and a firewall that only allows outbound traffic to whitelisted domains.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/farmer1st/klaude/main/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/farmer1st/klaude.git ~/klaude
cd ~/klaude
docker build -t klaude .
```

Then add to your shell:

```bash
alias klaude="~/klaude/klaude.sh"
alias klaude-upgrade="cd ~/klaude && git pull && docker build --no-cache -t klaude ."
```

## Requirements

- Docker Desktop (running)
- Claude Code credentials (API key or Claude Pro/Max login)

## Usage

```bash
klaude                              # interactive session in current directory
klaude -p "fix all lint errors"     # headless/print mode
klaude -p --max-turns 5 "query"    # limit turns
cat file.ts | klaude -p "explain"  # pipe mode
klaude -c                           # continue last session
```

## How It Works

```
You type: klaude "fix the tests"
          |
          v
  klaude.sh (host wrapper)
          |
          v
  docker run --cap-add=NET_ADMIN
    - mounts $(pwd) as /workspace
    - mounts ~/.claude (auth, settings, memory)
    - mounts ~/.gitconfig, ~/.ssh (read-only)
          |
          v
  entrypoint.sh (inside container)
    1. Sets up iptables firewall (default-deny)
    2. Whitelists: Claude API, GitHub, npm, ntfy.sh
    3. exec claude --dangerously-skip-permissions "$@"
```

## Security Model

| Layer | What it does |
|-------|-------------|
| **Docker container** | Filesystem isolation — can only see mounted volumes |
| **iptables firewall** | Network isolation — default-deny, only whitelisted domains |
| **`--dangerously-skip-permissions`** | Safe here because both layers above contain the blast radius |

### Whitelisted Domains

- `api.anthropic.com`, `api.claude.ai`, `claude.ai` — Claude API
- `registry.npmjs.org` — npm packages
- `github.com`, `api.github.com` — git operations
- `ntfy.sh` — push notifications
- `pypi.org`, `files.pythonhosted.org` — Python packages
- All private networks (`127.0.0.0/8`, `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`)

To add more domains, edit `ALLOWED_DOMAINS` in `entrypoint.sh`.

## Upgrade

```bash
klaude-upgrade
```

This pulls the latest repo and rebuilds the Docker image with the newest Claude Code version.

To pin a specific version, edit the `Dockerfile`:

```dockerfile
ARG CLAUDE_CODE_VERSION=1.0.0
```

## Volumes Mounted

| Host | Container | Mode |
|------|-----------|------|
| `$(pwd)` | `/workspace` | read-write |
| `~/.claude` | `/home/node/.claude` | read-write |
| `~/.gitconfig` | `/home/node/.gitconfig` | read-only |
| `~/.ssh` | `/home/node/.ssh` | read-only |

## Comparison: klaude vs native claude

| | `claude` (native + sandbox) | `klaude` (Docker) |
|---|---|---|
| Permission prompts | Rare (acceptEdits + allow rules) | Zero |
| Network isolation | macOS Seatbelt + domain allowlist | iptables firewall, default-deny |
| Filesystem isolation | Sandbox restricts writes to cwd | Full container isolation |
| Startup time | Instant | ~2s (container start) |
| Best for | Daily interactive dev | Automation, untrusted code, CI/CD |
