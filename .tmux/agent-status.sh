#!/usr/bin/env bash
# Marks the tmux pane running an AI coding agent (Claude Code, opencode, ...)
# as busy/waiting/idle. Fed by each agent's own hooks/plugins.
# Usage: agent-status.sh <busy|waiting|clear>
[ -n "$TMUX" ] && [ -n "$TMUX_PANE" ] || exit 0
case "$1" in
  clear) tmux set-option -p -t "$TMUX_PANE" -u @agent_state ;;
  *)
    tmux set-option -p -t "$TMUX_PANE" @agent_state "$1"
    # busy state is animated; start the spinner daemon if not already running
    if [ "$1" = "busy" ] && ! pgrep -f agent-spinner.sh >/dev/null 2>&1; then
      nohup "$HOME/.tmux/agent-spinner.sh" >/dev/null 2>&1 &
    fi
    ;;
esac
tmux refresh-client -S 2>/dev/null
exit 0
