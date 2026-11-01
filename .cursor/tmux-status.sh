#!/usr/bin/env bash
# Cursor hooks receive JSON on stdin and expect a JSON response. Keep status
# updates observational: never change prompt handling or permission decisions.
cat >/dev/null
"$HOME/.tmux/agent-status.sh" "$1" >/dev/null 2>&1
printf '{}\n'
