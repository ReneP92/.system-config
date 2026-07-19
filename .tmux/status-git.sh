#!/usr/bin/env bash
# Prints "repo · branch" for the git repo containing the given directory,
# nothing when outside a repo. Used by the status-right in ~/.tmux.conf.
cd "${1:-.}" 2>/dev/null || exit 0
top="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
branch="$(git branch --show-current 2>/dev/null)"
[ -n "$branch" ] || branch="$(git rev-parse --short HEAD 2>/dev/null)" # detached HEAD
printf '%s · %s\n' "${top##*/}" "$branch"
