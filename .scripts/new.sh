#!/usr/bin/env bash
# new-workspace.sh — create the next numbered workspace directory

set -euo pipefail

# Directory where workspaces live
WORKSPACES_DIR="${WORKSPACES_DIR:-$HOME/Workspaces}"

# Make sure the directory exists
if [[ ! -d "$WORKSPACES_DIR" ]]; then
	echo "Error: '$WORKSPACES_DIR' does not exist." >&2
	exit 1
fi

# Find the highest numeric prefix among directories matching "NN-*" or just "NN"
max=0
shopt -s nullglob
for entry in "$WORKSPACES_DIR"/*/; do
	base=$(basename "$entry")
	# Extract leading digits
	if [[ "$base" =~ ^([0-9]+) ]]; then
		num=$((10#${BASH_REMATCH[1]})) # force base-10 (avoid octal issues)
		if ((num > max)); then
			max=$num
		fi
	fi
done
shopt -u nullglob

next=$(printf "%02d" $((max + 1)))

# Optional workspace name from the first argument
name="${1:-}"

if [[ -n "$name" ]]; then
	new_dir="$WORKSPACES_DIR/${next}-${name}"
else
	new_dir="$WORKSPACES_DIR/${next}"
fi

if [[ -e "$new_dir" ]]; then
	echo "Error: '$new_dir' already exists." >&2
	exit 1
fi

mkdir -p "$new_dir"
echo "Created: $new_dir"
