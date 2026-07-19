#!/usr/bin/env bash
# Prints current CPU usage (user+sys, %) on macOS. Used by ~/.tmux.conf.
# Two top samples: the first reports since-boot averages, the second is live.
top -l 2 -n 0 -s 1 | awk '/CPU usage/ { u=$3; s=$5 } END { gsub("%","",u); gsub("%","",s); printf "%.0f%%\n", u+s }'
