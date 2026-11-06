#!/usr/bin/env bash
# Marks the tmux pane running an AI coding agent (Claude Code, opencode, ...)
# as idle/busy/waiting. Fed by each agent's own hooks/plugins.
# Usage: agent-status.sh <idle|busy|waiting|clear>
# (clear unsets the state: no agent in this pane)
#
# Claude Code hooks also pass their JSON input on stdin. Its transcript_path
# is remembered for busy/waiting so ~/.tmux/agent-spinner.sh can spot an Esc
# interrupt, which fires no hook at all.
[ -n "$TMUX" ] && [ -n "$TMUX_PANE" ] || exit 0
state=$1
[ "$state" = clear ] && state=
event='' transcript=''
if [ ! -t 0 ]; then
  IFS=$'\t' read -r event transcript < <(jq -r '[.hook_event_name // "", .transcript_path // ""] | @tsv' 2>/dev/null)
fi
[ "$state" = busy ] || [ "$state" = waiting ] || transcript=

# Some hooks fire on every tool call; only write when the state changes, or
# when a new prompt starts a turn (the pane may still show busy from a turn
# whose interrupt went unnoticed).
if [ "$event" = UserPromptSubmit ] ||
  [ "$(tmux show-options -pqv -t "$TMUX_PANE" @agent_state 2>/dev/null)" != "$state" ]; then
  if [ -z "$state" ]; then
    tmux set-option -p -t "$TMUX_PANE" -u @agent_state
  else
    tmux set-option -p -t "$TMUX_PANE" @agent_state "$state"
  fi
  tmux set-option -p -t "$TMUX_PANE" -u @agent_misses
  if [ -n "$transcript" ]; then
    # Only entries written after this point can interrupt the new state. A
    # new session's transcript is created after its first prompt is sent.
    offset=0
    [ -f "$transcript" ] && offset=$(wc -c <"$transcript" | tr -d ' ')
    tmux set-option -p -t "$TMUX_PANE" @agent_transcript "$transcript" \; \
      set-option -p -t "$TMUX_PANE" @agent_transcript_offset "$offset"
  else
    tmux set-option -p -t "$TMUX_PANE" -u @agent_transcript \; \
      set-option -p -t "$TMUX_PANE" -u @agent_transcript_offset
  fi
  tmux refresh-client -S 2>/dev/null
fi

# The daemon animates busy panes and watches busy/waiting ones for
# interrupts. Checked on every call so a daemon that died gets replaced.
if { [ "$state" = busy ] || [ "$state" = waiting ]; } &&
  ! pgrep -f agent-spinner.sh >/dev/null 2>&1; then
  nohup "$HOME/.tmux/agent-spinner.sh" >/dev/null 2>&1 &
fi
exit 0
