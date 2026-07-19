#!/usr/bin/env bash
# Marks the tmux window containing this Claude session as busy/waiting/idle.
# Usage: tmux-claude-status.sh <busy|waiting|clear>
[ -n "$TMUX" ] && [ -n "$TMUX_PANE" ] || exit 0
case "$1" in
  clear) tmux set-option -w -t "$TMUX_PANE" -u @claude_state ;;
  *)
    tmux set-option -w -t "$TMUX_PANE" @claude_state "$1"
    # busy state is animated; start the spinner daemon if not already running
    if [ "$1" = "busy" ] && ! pgrep -f tmux-claude-spinner.sh >/dev/null 2>&1; then
      nohup "$HOME/.claude/hooks/tmux-claude-spinner.sh" >/dev/null 2>&1 &
    fi
    ;;
esac
tmux refresh-client -S 2>/dev/null
exit 0
