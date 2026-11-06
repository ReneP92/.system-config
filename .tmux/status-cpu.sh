#!/usr/bin/env bash
# Prints current CPU usage (user+sys, %) on macOS. Used by ~/.tmux.conf.
#
# A sample takes a second (two top samples: the first reports since-boot
# averages, the second is live), but tmux reruns status jobs far more often
# than status-interval: on any status redraw once the last run is a second
# old, and on every `refresh-client -S`, which kills a run still in progress
# (its top lived on, orphaned, so they piled up). So this prints the last
# sample at once and takes the next one in the background, at most every
# two seconds and one at a time.
cache="${TMPDIR:-/tmp}/tmux-status-cpu"
lock="$cache.lock"

cat "$cache" 2>/dev/null

now=$(date +%s)
age() {
  echo $((now - $(stat -f %m "$1" 2>/dev/null || echo 0)))
}
[ "$(age "$cache")" -ge 2 ] || exit 0
if ! mkdir "$lock" 2>/dev/null; then
  # a sample takes a second; a lock this old was left by a killed sampler
  [ "$(age "$lock")" -ge 10 ] && rmdir "$lock" 2>/dev/null && mkdir "$lock" 2>/dev/null || exit 0
fi
(
  if top -l 2 -n 0 -s 1 |
    awk '/CPU usage/ { u=$3; s=$5 } END { gsub("%","",u); gsub("%","",s); printf "%.0f%%\n", u+s }' >"$cache.tmp"; then
    mv "$cache.tmp" "$cache"
  fi
  rmdir "$lock"
) </dev/null >/dev/null 2>&1 &
