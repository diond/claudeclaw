# tmux Cheatsheet

Quick reference for interacting with ClaudeClaw agent sessions.

## Basics

| Command | What it does |
|---------|-------------|
| `tmux ls` | List all running sessions |
| `tmux attach -t agent-primary` | Attach to primary agent's session |
| `tmux attach -t agent-alpha` | Attach to alpha agent's session |
| `Ctrl+B, then D` | Detach from session (leave it running) |
| `tmux kill-session -t agent-primary` | Kill a specific session |

## Viewing Agent Sessions via SSH

```bash
# List sessions
ssh -i KEY ubuntu@IP 'tmux ls'

# Attach (interactive — needs -t flag)
ssh -i KEY -t ubuntu@IP 'tmux attach -t agent-primary'

# View logs without attaching
ssh -i KEY ubuntu@IP 'tail -20 ~/workspace/session.log'
ssh -i KEY ubuntu@IP 'tail -20 ~/workspace/agents/alpha/session.log'

# Follow logs in real-time
ssh -i KEY ubuntu@IP 'tail -f ~/workspace/agents/alpha/session.log'
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
