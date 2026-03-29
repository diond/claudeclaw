# Troubleshooting

Common issues and fixes for ClaudeClaw Hardened deployments.

## Bot shows "typing" but never responds

**Cause:** A duplicate MCP server or Telegram plugin instance is consuming messages before the agent sees them.

**Fix:** Ensure `.mcp.json` in the agent directory contains only `{"mcpServers":{}}`. The Telegram connection is handled by the `--channels` flag, not MCP.

## "Permission denied" on SSH

**Fix:**
```bash
chmod 400 ~/.ssh/LightsailDefaultKey-us-east-1.pem
```

SSH keys must have restricted permissions (400 or 600) or SSH refuses to use them.

## Claude Code auth expired

**Fix:** SSH in and re-authenticate:
```bash
ssh -i KEY ubuntu@IP
claude
# Follow the device code flow again
```

## Agent keeps restarting (restart loop)

**Cause:** The Claude Code process is crashing immediately, hitting the systemd restart limit.

**Diagnose:**
```bash
# Check session log
ssh -i KEY ubuntu@IP 'cat ~/workspace/session.log'
ssh -i KEY ubuntu@IP 'cat ~/workspace/agents/alpha/session.log'

# Check systemd status
ssh -i KEY ubuntu@IP 'systemctl --user status claudeclaw@primary'

# Check systemd journal
ssh -i KEY ubuntu@IP 'journalctl --user -u claudeclaw@primary --no-pager -n 50'
```

**Common causes:**
- Auth expired (re-authenticate)
- Missing Telegram plugin (reinstall)
- Missing bot token (re-run configure-agent.sh)
- Node.js or Bun not in PATH (re-run bootstrap)

## Healthcheck cron not running

**Diagnose:**
```bash
# Check if cron is installed
ssh -i KEY ubuntu@IP 'crontab -l'

# Check healthcheck log
ssh -i KEY ubuntu@IP 'cat ~/workspace/shared/memory/healthcheck.log'
```

**Common causes:**
- Missing `XDG_RUNTIME_DIR` in crontab — `systemctl --user` commands need this
- Wrong user ID in `/run/user/UID` — check with `id -u`
- Using `~` instead of full paths in crontab entries

## Agent can't see shared files

**Cause:** Sub-agent was started without `--add-dir ~/workspace`.

**Fix:** The systemd service template handles this automatically for non-primary agents. If you're running manually, always include:
```bash
claude --add-dir ~/workspace --channels plugin:telegram@claude-plugins-official
```

## tmux session exists but agent is dead inside

**Cause:** The Claude Code process exited but tmux kept the pane open.

**Fix:** The healthcheck cron detects this (checks `pane_dead` flag) and restarts automatically. To fix manually:
```bash
tmux kill-session -t agent-primary
systemctl --user restart claudeclaw@primary
```

## Agent stalled on `.claude/` write prompt

**Cause:** Since Claude Code v2.1.78, `bypassPermissions` still prompts for writes to `.claude/`, `.git/`, `.vscode/`, and `.idea/` directories.

**Fix:** Attach to the tmux session and approve or deny the prompt:
```bash
ssh -i KEY -t ubuntu@IP 'tmux attach -t agent-primary'
```

Agents generally don't need to write to `.claude/` during normal operation, so this is rare.

## Firewall blocking connections

**Diagnose:**
```bash
ssh -i KEY ubuntu@IP 'sudo ufw status'
```

**Expected output:** SSH (22) allowed, everything else denied incoming, all outgoing allowed. Claude Code needs outgoing HTTPS (443) which is allowed by default.

## Out of disk space

**Diagnose:**
```bash
ssh -i KEY ubuntu@IP 'df -h'
```

**Common culprits:**
- Large session logs: `truncate -s 0 ~/workspace/session.log`
- npm cache: `npm cache clean --force`
- Old node_modules: find and remove unused ones
