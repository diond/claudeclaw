# Lightsail Quickstart

Step-by-step guide to deploying ClaudeClaw Hardened on AWS Lightsail.

## 1. Create a Lightsail Instance

1. Go to [AWS Lightsail Console](https://lightsail.aws.amazon.com/)
2. Click "Create instance"
3. Select **Linux/Unix** platform, **Ubuntu 24.04 LTS**
4. Choose the **$12/mo plan** (2 GB RAM, 2 vCPU, 60 GB SSD)
5. Name it (e.g., `claudeclaw`)
6. Click "Create instance"

## 2. Attach a Static IP

1. In the Lightsail console, go to **Networking** > **Static IPs**
2. Create and attach a static IP to your instance
3. Note the IP address — you'll need it for all SSH commands

## 3. Download Your SSH Key

1. Go to Lightsail **Account** page
2. Under **SSH keys**, download the default key for your region
3. Save it to `~/.ssh/` on your Mac (e.g., `~/.ssh/LightsailDefaultKey-us-east-1.pem`)
4. Set permissions:
   ```bash
   chmod 400 ~/.ssh/LightsailDefaultKey-us-east-1.pem
   ```

## 4. Test SSH Connection

```bash
ssh -i ~/.ssh/LightsailDefaultKey-us-east-1.pem ubuntu@YOUR_IP
```

You should get a shell prompt. Type `exit` to disconnect.

## 5. Deploy Setup Files

```bash
# Create workspace on server
ssh -i KEY ubuntu@IP 'mkdir -p ~/workspace'

# Copy setup scripts
scp -i KEY -r setup/ ubuntu@IP:~/workspace/

# Run bootstrap (3-5 minutes)
ssh -i KEY ubuntu@IP 'bash ~/workspace/setup/bootstrap.sh'
```

## 6. Manual Steps (Cannot Be Automated)

### Authenticate Claude Code

```bash
ssh -i KEY ubuntu@IP
claude
# Follow the URL + device code flow to authenticate
# Exit Claude Code after auth: Ctrl+C
```

### Install Telegram Plugin

```bash
# Still in SSH session, start claude again
claude
# Type these commands in the Claude Code prompt:
#   /plugin marketplace add anthropics/claude-plugins-official
#   /plugin install telegram@claude-plugins-official
#   /reload-plugins
# Exit: Ctrl+C
exit
```

## 7. Create Telegram Bots

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts for each agent (primary, alpha, etc.)
3. Save each bot token
4. Get your Telegram user ID from [@userinfobot](https://t.me/userinfobot)

## 8. Configure Agents

```bash
# Primary agent
ssh -i KEY ubuntu@IP 'bash ~/workspace/setup/configure-agent.sh primary BOT_TOKEN TELEGRAM_USER_ID'

# Sub-agents (optional)
ssh -i KEY ubuntu@IP 'bash ~/workspace/setup/configure-agent.sh alpha BOT_TOKEN_ALPHA TELEGRAM_USER_ID'
```

## 9. Edit Secrets

```bash
ssh -i KEY -t ubuntu@IP 'nano ~/workspace/.env.agents'
# Replace REPLACE_ME values with your actual API keys
# Save: Ctrl+O, Exit: Ctrl+X
```

## 10. Start Agents

```bash
# Enable and start
ssh -i KEY ubuntu@IP 'systemctl --user enable claudeclaw@primary && systemctl --user start claudeclaw@primary'

# Verify
ssh -i KEY ubuntu@IP 'tmux ls'
```

## 11. Install Healthcheck Cron

```bash
USER_UID=$(ssh -i KEY ubuntu@IP 'id -u')
ssh -i KEY ubuntu@IP "{ crontab -l 2>/dev/null; echo 'XDG_RUNTIME_DIR=/run/user/$USER_UID'; echo '*/5 * * * * /bin/bash /home/ubuntu/workspace/setup/healthcheck.sh'; } | crontab -"
```

## 12. Verify

1. Run `ssh -i KEY ubuntu@IP 'tmux ls'` — you should see `agent-primary` (and others)
2. Send a test message to your Telegram bot — the agent should respond
3. Check service status: `ssh -i KEY ubuntu@IP 'systemctl --user status claudeclaw@primary'`

Replace `KEY` with your SSH key path and `IP` with your Lightsail static IP throughout.
