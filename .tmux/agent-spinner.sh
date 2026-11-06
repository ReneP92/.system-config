#!/usr/bin/env bash
# Agent daemon, started on demand by agent-status.sh. Runs while any tmux
# pane is busy, or waiting with a known Claude Code transcript, then exits.
#
# 1. Cycles @agent_spinner_frame for busy panes. tmux throttles #() job
#    output to one status update per second, so the animation is driven by
#    option writes + explicit status-only refreshes, which are not throttled.
# 2. About once a second, reconciles Claude Code panes (the ones with a
#    transcript) with what Claude is actually doing, covering moments that
#    fire no hook:
#    - Esc after output started, or on a permission prompt or question:
#      Claude only appends a "[Request interrupted by user...]" transcript
#      entry -> idle.
#    - Esc while still thinking: the prompt is put back in the input box and
#      nothing is written at all. Claude's working line ("✶ Grooving… (8s ·
#      thinking)") disappears, so a busy pane without it for 3 checks in a
#      row -> idle.
#    - A permission prompt was approved and the tool is running: PostToolUse
#      only fires once it finishes, but the working line is back -> busy.

# One daemon per tmux server: hooks can start it from several processes at
# once. The flock sits on fd 9's open file, which the shell keeps for its
# lifetime, so it is released however the daemon exits (even kill -9) and
# never goes stale. If the lock can't be set up, run unguarded rather than
# leave the spinner frozen.
if [ -n "$TMUX" ] && exec 9>>"${TMUX%%,*}.agent-spinner.lock"; then
  perl -MFcntl=:flock -e 'open(my $fh, ">&=", 9) or exit 2; flock($fh, LOCK_EX | LOCK_NB) or exit 1'
  [ $? -eq 1 ] && exit 0
fi 2>/dev/null

frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
i=0

# Prints whether the last message written to $1 after byte offset $2 is an
# interrupt marker. Partial (still being written) lines are skipped.
interrupted() {
  tail -c +"$(($2 + 1))" "$1" 2>/dev/null | tail -n 20 | jq -nRr '
    [inputs | fromjson? | select(.type == "user" or .type == "assistant")]
    | last | .message.content
    | if type == "array" then (.[0].text // "") else (. // "") end
    | startswith("[Request interrupted by user")' 2>/dev/null
}

# Whether Claude's working line is on the pane's screen.
working() {
  tmux capture-pane -p -t "$1" 2>/dev/null | grep -qE '^[^ ]+ [^ ].*… \([0-9]+[smh]'
}

set_state() {
  tmux set-option -p -t "$1" @agent_state "$2" \; set-option -p -t "$1" -u @agent_misses
  if [ "$2" = idle ]; then
    tmux set-option -p -t "$1" -u @agent_transcript \; \
      set-option -p -t "$1" -u @agent_transcript_offset
  fi
}

# Panes needing attention, as unit-separated fields (bash merges runs of
# whitespace separators, which would shift empty fields). A pane back at a
# plain shell is skipped (its agent died without running its exit hook),
# matching the status bar.
US=$'\x1f'
panes() {
  tmux list-panes -a -F "#{pane_id}$US#{@agent_state}$US#{@agent_transcript}$US#{@agent_transcript_offset}$US#{@agent_misses}$US#{pane_current_command}" 2>/dev/null |
    awk -F"$US" '$6 !~ /^-?(zsh|bash|fish|sh)$/ && ($2 == "busy" || ($2 == "waiting" && $3 != ""))' |
    cut -d"$US" -f1-5
}

while list=$(panes) && [ -n "$list" ]; do
  if (( i % 7 == 0 )); then
    while IFS=$US read -r pane state transcript offset misses; do
      [ -n "$transcript" ] || continue
      if [ "$(interrupted "$transcript" "${offset:-0}")" = true ]; then
        set_state "$pane" idle
      elif working "$pane"; then
        if [ "$state" = waiting ]; then
          set_state "$pane" busy
        elif [ -n "$misses" ]; then
          tmux set-option -p -t "$pane" -u @agent_misses
        fi
      elif [ "$state" = busy ]; then
        misses=$(( ${misses:-0} + 1 ))
        if (( misses >= 3 )); then
          set_state "$pane" idle
        else
          tmux set-option -p -t "$pane" @agent_misses "$misses"
        fi
      fi
    done <<<"$list"
  fi
  tmux set-option -g @agent_spinner_frame "${frames[i % ${#frames[@]}]}"
  while IFS= read -r client; do
    tmux refresh-client -S -t "$client" 2>/dev/null
  done < <(tmux list-clients -F '#{client_name}' 2>/dev/null)
  i=$(( (i + 1) % 70 ))
  sleep 0.15
done
tmux set-option -gu @agent_spinner_frame 2>/dev/null
exit 0
