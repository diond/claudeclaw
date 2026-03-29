#!/usr/bin/env bash
# Run via system cron every 5 minutes to verify agents are alive
# Add/remove agent names in the AGENTS array as you scale

AGENTS=(primary alpha beta gamma)
LOG="$HOME/workspace/shared/memory/healthcheck.log"

for agent in "${AGENTS[@]}"; do
  if systemctl --user is-enabled "claudeclaw@$agent" &>/dev/null; then
    if ! tmux -L "agent-$agent" has-session -t "agent-$agent" 2>/dev/null; then
      # tmux session is gone entirely
      echo "$(date): Agent $agent — tmux session missing, restarting" >> "$LOG"
      systemctl --user restart "claudeclaw@$agent"
    elif tmux -L "agent-$agent" list-panes -t "agent-$agent" -F '#{pane_dead}' 2>/dev/null | grep -q "1"; then
      # tmux session exists but the command inside has exited (pane_dead=1)
      echo "$(date): Agent $agent — process exited inside tmux, restarting" >> "$LOG"
      tmux -L "agent-$agent" kill-session -t "agent-$agent" 2>/dev/null
      systemctl --user restart "claudeclaw@$agent"
    fi
  fi
done
