#!/usr/bin/env bash
set -euo pipefail

# Bidirectional sync between:
#   1) ~/.config/nvim/
#   2) .system-config/root/.config/nvim/
#
# For each relative path present in either tree:
# - If it exists only on one side, it is copied to the other.
# - If it exists on both sides, the newer file overwrites the older file.
# - If timestamps are equal, nothing happens.
#
# Notes:
# - This script does not delete anything.
# - Copies preserve permissions and timestamps.

REPO_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

LOCAL_DIR="${HOME}/.config/nvim"
REPO_DIR="${REPO_ROOT_DIR}/root/.config/nvim"

TMPFILE=""

usage() {
	cat <<EOF
Usage: $(basename "$0") [--dry-run]

Syncs between:
  ${LOCAL_DIR}/
  ${REPO_DIR}/

Based on per-file modification time: newer overwrites older.
EOF
}

DRY_RUN=0
case "${1:-}" in
	"" ) ;;
	--dry-run ) DRY_RUN=1 ;;
	-h|--help ) usage; exit 0 ;;
	* )
		echo "Unknown argument: $1" >&2
		usage >&2
		exit 2
		;;
esac

log_update() {
	# Logs when a file is copied/updated.
	# Args: rel direction reason
	# direction: LOCAL->REPO or REPO->LOCAL
	local rel="$1"
	local direction="$2"
	local reason="$3"
	if [[ $DRY_RUN -eq 1 ]]; then
		echo "[DRY-RUN] UPDATE ${direction}: ${rel} (${reason})"
	else
		echo "UPDATE ${direction}: ${rel} (${reason})"
	fi
}

mtime_epoch() {
	# Prints mtime in seconds since epoch for a given path.
	# macOS: stat -f %m
	# GNU:   stat -c %Y
	local path="$1"
	if stat -f %m "$path" >/dev/null 2>&1; then
		stat -f %m "$path"
	else
		stat -c %Y "$path"
	fi
}

copy_one() {
	local src="$1"
	local dst="$2"
	local dst_dir
	dst_dir="$(dirname "$dst")"

	if [[ $DRY_RUN -eq 1 ]]; then
		echo "COPY: $src -> $dst"
		return 0
	fi

	mkdir -p "$dst_dir"
	# rsync preserves permissions, mtimes, symlinks, etc.
	rsync -a -- "$src" "$dst"
}

ensure_dirs_exist() {
	if [[ ! -d "$LOCAL_DIR" ]]; then
		mkdir -p "$LOCAL_DIR"
	fi
	if [[ ! -d "$REPO_DIR" ]]; then
		mkdir -p "$REPO_DIR"
	fi
}

is_under_dir() {
	local dir="$1"
	local path="$2"
	case "$path" in
		"$dir"/*) return 0 ;;
		*) return 1 ;;
	esac
}

sync_relative_path() {
	local rel="$1"
	local a="$LOCAL_DIR/$rel"
	local b="$REPO_DIR/$rel"

	local a_exists=0
	local b_exists=0
	[[ -e "$a" ]] && a_exists=1
	[[ -e "$b" ]] && b_exists=1

	if [[ $a_exists -eq 1 && $b_exists -eq 0 ]]; then
		log_update "$rel" "LOCAL->REPO" "missing in repo"
		copy_one "$a" "$b"
		return 0
	fi

	if [[ $a_exists -eq 0 && $b_exists -eq 1 ]]; then
		log_update "$rel" "REPO->LOCAL" "missing locally"
		copy_one "$b" "$a"
		return 0
	fi

	# Both exist.
	# If one is a directory and the other is not, copy the non-directory onto the other side
	# only when the source is not a directory. (We only sync files/symlinks; directories are created.)
	if [[ -d "$a" || -d "$b" ]]; then
		# Directories: nothing to copy directly. Their contents are handled by file-level sync.
		return 0
	fi

	local a_mtime b_mtime
	a_mtime="$(mtime_epoch "$a")"
	b_mtime="$(mtime_epoch "$b")"

	if [[ "$a_mtime" -gt "$b_mtime" ]]; then
		log_update "$rel" "LOCAL->REPO" "local is newer"
		copy_one "$a" "$b"
	elif [[ "$b_mtime" -gt "$a_mtime" ]]; then
		log_update "$rel" "REPO->LOCAL" "repo is newer"
		copy_one "$b" "$a"
	fi
}

main() {
	ensure_dirs_exist

	# Build a unique set of relative paths from both trees.
	# We include directories too (they no-op in sync_relative_path), which is fine.
	TMPFILE="$(mktemp -t nvim-sync.XXXXXX)"
	trap '[[ -n "${TMPFILE:-}" ]] && rm -f -- "$TMPFILE"' EXIT

	# Collect relpaths from LOCAL_DIR
	( cd "$LOCAL_DIR" && find . -mindepth 1 -print0 ) \
		| while IFS= read -r -d '' p; do
			printf '%s\n' "${p#./}"
		done >>"$TMPFILE"

	# Collect relpaths from REPO_DIR
	( cd "$REPO_DIR" && find . -mindepth 1 -print0 ) \
		| while IFS= read -r -d '' p; do
			printf '%s\n' "${p#./}"
		done >>"$TMPFILE"

	LC_ALL=C sort -u "$TMPFILE" | while IFS= read -r rel; do
		# Skip empty lines defensively.
		[[ -z "$rel" ]] && continue
		sync_relative_path "$rel"
	done
}

main
