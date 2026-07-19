#!/usr/bin/env bash
# Spinner daemon: cycles @claude_spinner_frame while any tmux window has
# @claude_state=busy, then exits. Started on demand by tmux-claude-status.sh.
# tmux throttles #() job output to one status update per second, so the
# animation is driven by option writes + explicit status-only refreshes,
# which are not throttled.
frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
i=0
while tmux list-windows -a -F '#{@claude_state}' 2>/dev/null | grep -q busy; do
  tmux set-option -g @claude_spinner_frame "${frames[i]}"
  while IFS= read -r client; do
    tmux refresh-client -S -t "$client" 2>/dev/null
  done < <(tmux list-clients -F '#{client_name}' 2>/dev/null)
  i=$(( (i + 1) % ${#frames[@]} ))
  sleep 0.15
done
tmux set-option -gu @claude_spinner_frame 2>/dev/null
exit 0
