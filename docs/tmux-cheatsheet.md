# tmux Cheatsheet

Quick reference for interacting with ClaudeClaw agent sessions.

## Basics

Each agent runs on its own tmux socket (`-L agent-<name>`). You must specify the socket to interact with a specific agent.

| Command | What it does |
|---------|-------------|
| `tmux -L agent-primary ls` | List primary agent's session |
| `tmux -L agent-primary attach -t agent-primary` | Attach to primary agent |
| `tmux -L agent-alpha attach -t agent-alpha` | Attach to alpha agent |
| `Ctrl+B, then D` | Detach from session (leave it running) |
| `for a in primary alpha beta gamma; do tmux -L "agent-$a" ls 2>/dev/null; done` | List all agent sessions |

## Viewing Agent Sessions via SSH

```bash
# List all agent sessions
ssh -i KEY ubuntu@IP 'for a in primary alpha beta gamma; do tmux -L "agent-$a" ls 2>/dev/null; done'

# Attach (interactive — needs -t flag)
ssh -i KEY -t ubuntu@IP 'tmux -L agent-primary attach -t agent-primary'

# Attach to a sub-agent
ssh -i KEY -t ubuntu@IP 'tmux -L agent-alpha attach -t agent-alpha'
```

## Scrollback

While attached to a tmux session:

1. Press `Ctrl+B`, then `[` to enter scroll mode
2. Use arrow keys or `Page Up`/`Page Down` to scroll
3. Press `q` to exit scroll mode

## Multiple Panes (Advanced)

| Command | What it does |
|---------|-------------|
| `Ctrl+B, then %` | Split vertically |
| `Ctrl+B, then "` | Split horizontally |
| `Ctrl+B, then arrow key` | Switch between panes |
| `Ctrl+B, then x` | Close current pane |

## Session Management with systemd

```bash
# Start an agent (creates tmux session automatically)
systemctl --user start claudeclaw@primary

# Stop an agent (kills tmux session)
systemctl --user stop claudeclaw@primary

# Restart an agent
systemctl --user restart claudeclaw@primary

# Check status
systemctl --user status claudeclaw@primary

# View systemd logs
journalctl --user -u claudeclaw@primary --no-pager -n 50
```

## Tips

- **Never kill a tmux session manually** if systemd is managing it — use `systemctl --user stop` instead, so systemd knows the agent is down.
- **Detach, don't exit** — pressing `Ctrl+C` or typing `exit` inside the tmux session kills the Claude Code process. Use `Ctrl+B, D` to detach safely.
- **Session naming** — all agent sessions follow the pattern `agent-<name>` (e.g., `agent-primary`, `agent-alpha`).
- **Per-agent sockets** — each agent uses its own tmux socket (`-L agent-<name>`) so systemd can track each server process independently. Always include `-L agent-<name>` in tmux commands.
