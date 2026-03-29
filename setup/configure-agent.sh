#!/usr/bin/env bash
set -euo pipefail

AGENT_NAME="${1:?Usage: configure-agent.sh <name> <bot-token> <telegram-user-id>}"
BOT_TOKEN="${2:?}"
USER_ID="${3:?}"

WORKSPACE="$HOME/workspace"

if [ "$AGENT_NAME" = "primary" ]; then
  AGENT_PATH="$WORKSPACE"
else
  AGENT_PATH="$WORKSPACE/agents/$AGENT_NAME"
fi

mkdir -p "$AGENT_PATH/.claude/telegram"

# Telegram bot token
echo "TELEGRAM_BOT_TOKEN=$BOT_TOKEN" > "$AGENT_PATH/.claude/telegram/.env"

# Telegram access control
cat > "$AGENT_PATH/.claude/telegram/access.json" << EOF
{
  "dmPolicy": "allowlist",
  "allowFrom": ["$USER_ID"],
  "groups": {},
  "pending": {}
}
EOF

# Settings with environment variables for MCP subprocess
cat > "$AGENT_PATH/.claude/settings.local.json" << EOF
{
  "env": {
    "TELEGRAM_STATE_DIR": "$AGENT_PATH/.claude/telegram",
    "TELEGRAM_BOT_TOKEN": "$BOT_TOKEN"
  }
}
EOF

# Empty MCP config (channels flag handles Telegram, not MCP)
echo '{"mcpServers":{}}' > "$AGENT_PATH/.mcp.json"

# Project-level permissions (protect .env files)
cat > "$AGENT_PATH/.claude/settings.json" << EOF
{
  "permissions": {
    "deny": [
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Edit(**/.env)",
      "Edit(**/.env.*)",
      "Write(**/.env)",
      "Write(**/.env.*)"
    ]
  }
}
EOF

echo "Agent '$AGENT_NAME' configured at $AGENT_PATH"
echo "Bot token: ${BOT_TOKEN:0:10}..."
echo "Telegram user: $USER_ID"

# Lock down secret files
chmod 600 "$AGENT_PATH/.claude/telegram/.env"
chmod 600 "$AGENT_PATH/.claude/settings.local.json"
chmod 700 "$AGENT_PATH/.claude/telegram"
echo "File permissions set (600 on secrets, 700 on telegram dir)."
