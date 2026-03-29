#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# ClaudeClaw Hardened — Lightsail Bootstrap
# Copy setup/ directory to server first, then run:
#   ssh user@lightsail 'mkdir -p ~/workspace'
#   scp -r setup/ user@lightsail:~/workspace/
#   ssh user@lightsail 'bash ~/workspace/setup/bootstrap.sh'
# ============================================================

echo "=== 1. System updates ==="
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y tmux git curl jq htop unzip

echo "=== 2. Install Bun ==="
if ! command -v bun &>/dev/null; then
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
else
  echo "Bun already installed: $(bun --version)"
fi

echo "=== 3. Install Node.js (LTS) ==="
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
else
  echo "Node already installed: $(node --version)"
fi

echo "=== 4. Install Claude Code ==="
# NOTE: Verify current package name at https://docs.claude.com before running.
# The package name may have changed since this script was written.
if ! command -v claude &>/dev/null; then
  sudo npm install -g @anthropic-ai/claude-code
else
  echo "Claude Code already installed: $(claude --version 2>/dev/null || echo 'installed')"
fi

echo "=== 5. Authenticate Claude Code ==="
echo "Run 'claude' and complete the device code auth flow."
echo "Open the URL on your phone/laptop to authenticate."

echo "=== 6. Create workspace structure ==="
WORKSPACE="$HOME/workspace"
mkdir -p "$WORKSPACE"/{agents/{alpha,beta,gamma},shared/memory,.claude/skills}
mkdir -p "$WORKSPACE/agents/alpha/"{.claude/telegram,memory}
mkdir -p "$WORKSPACE/agents/beta/"{.claude/telegram,memory}
mkdir -p "$WORKSPACE/agents/gamma/"{.claude/telegram,memory}

echo "=== 7. Create systemd service directory ==="
mkdir -p "$HOME/.config/systemd/user"

echo "=== 8. Create global Claude Code settings ==="
# This is the GLOBAL settings file at ~/.claude/settings.json (NOT inside the workspace).
# It sets bypassPermissions mode and denies catastrophic commands across ALL projects.
mkdir -p "$HOME/.claude"
cat > "$HOME/.claude/settings.json" << 'SETTINGS'
{
  "permissions": {
    "defaultMode": "bypassPermissions",
    "deny": [
      "Bash(rm -rf *)",
      "Bash(rm -r /*)",
      "Bash(rm -r ~*)",
      "Bash(git push --force *)",
      "Bash(git push -f *)",
      "Bash(git reset --hard *)",
      "Bash(git clean -fd *)",
      "Bash(git clean -f *)",
      "Bash(git checkout -- .)",
      "Bash(sudo *)",
      "Bash(chmod -R 777 *)",
      "Bash(mkfs *)",
      "Bash(dd *)",
      "Bash(shutdown *)",
      "Bash(reboot *)",
      "Bash(systemctl *)",
      "Bash(kill -9 *)",
      "Bash(killall *)",
      "Bash(pkill *)",
      "Bash(format *)",
      "Bash(fdisk *)",
      "Bash(parted *)",
      "Bash(apt remove *)",
      "Bash(apt purge *)",
      "Bash(apt-get remove *)",
      "Bash(apt-get purge *)"
    ]
  }
}
SETTINGS
echo "Global Claude Code settings created at ~/.claude/settings.json"

echo "=== 9. Set timezone ==="
# Change to your local timezone so cron schedules align with your workday
sudo timedatectl set-timezone America/Mexico_City

echo "=== 10. Create centralized secrets template ==="
if [ ! -f "$WORKSPACE/.env.agents" ]; then
  cat > "$WORKSPACE/.env.agents" << 'ENVTEMPLATE'
# Shared secrets for systemd EnvironmentFile
# Edit this file with your actual API keys after bootstrap completes
# These are injected as environment variables into all agent sessions
OPENROUTER_API_KEY=sk-or-REPLACE_ME
SUPABASE_SERVICE_ROLE_KEY=REPLACE_ME
ELEVENLABS_API_KEY=REPLACE_ME
ENVTEMPLATE
  chmod 600 "$WORKSPACE/.env.agents"
  echo "Created .env.agents template. Edit with your actual API keys."
else
  echo ".env.agents already exists, skipping."
fi

echo "=== 11. Enable lingering (keeps user services running after SSH disconnect) ==="
sudo loginctl enable-linger "$USER"

echo "=== 12. Copy systemd service template ==="
if [ -f "$(dirname "$0")/claudeclaw@.service" ]; then
  cp "$(dirname "$0")/claudeclaw@.service" "$HOME/.config/systemd/user/"
  systemctl --user daemon-reload
  echo "systemd service template installed and daemon reloaded."
else
  echo "WARNING: claudeclaw@.service not found. Copy it manually to ~/.config/systemd/user/"
fi

echo "=== 13. SSH hardening (key-only auth) ==="
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

echo "=== 14. Firewall setup ==="
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw --force enable

echo "=== 15. Install Telegram plugin ==="
echo "Run inside a Claude Code session:"
echo "  /plugin marketplace add anthropics/claude-plugins-official"
echo "  /plugin install telegram@claude-plugins-official"
echo "  /reload-plugins"

echo "=== Bootstrap complete ==="
echo "Next steps:"
echo "  1. Authenticate Claude Code: claude"
echo "  2. Install Telegram plugin (commands above)"
echo "  3. Configure agents: bash ~/workspace/setup/configure-agent.sh <name> <bot-token> <telegram-user-id>"
echo "  4. Start agents: systemctl --user start claudeclaw@primary"
