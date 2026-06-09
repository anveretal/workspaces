#!/usr/bin/env bash

set -euo pipefail

show_progress() {
    local current=$1 total=$2 width=30
    local percent=$(( 100 * current / total ))
    local filled=$(( width * current / total ))
    printf "\r[%-${width}s] %3d%%" "$(printf '#%.0s' $(seq 1 $filled))" "$percent"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

all_dirs=()
while IFS= read -r d; do
    all_dirs+=("${d%/}")
done < <(for d in */; do printf '%s\n' "$d"; done | sort)

if [[ ${#all_dirs[@]} -eq 0 ]]; then
    echo "No directories to process."
    exit 0
fi

valid=()
suffixes=()

for d in "${all_dirs[@]}"; do
    if [[ $d =~ ^([0-9][0-9])-(.+)$ ]]; then
        valid+=("$d")
        suffixes+=("${BASH_REMATCH[2]}")
    fi
done

if [[ ${#valid[@]} -eq 0 ]]; then
    echo "No directories with NN- prefix to renumber."
    exit 0
fi

if [[ ${#valid[@]} -gt 99 ]]; then
    echo "Error: too many directories (${#valid[@]}, maximum 99)."
    exit 1
fi

new_names=()
for i in "${!valid[@]}"; do
    num=$(printf "%02d" $((i + 1)))
    new_names+=("${num}-${suffixes[$i]}")
done

changes=false
for i in "${!valid[@]}"; do
    if [[ "${valid[$i]}" != "${new_names[$i]}" ]]; then
        changes=true
        break
    fi
done

if ! $changes; then
    echo "Directories are already correctly numbered."
    exit 0
fi

max_len=0
for old in "${valid[@]}"; do
    (( ${#old} > max_len )) && max_len=${#old}
done
max_len=$(( max_len > 8 ? max_len : 8 ))

echo "Planned renames:"
echo

for i in "${!valid[@]}"; do
    old="${valid[$i]}"
    new="${new_names[$i]}"
    if [[ "$old" != "$new" ]]; then
        printf "  %-*s  →  %s\n" "$max_len" "$old" "$new"
    else
        printf "  %-*s  →  (unchanged)\n" "$max_len" "$old"
    fi
done
echo

while true; do
    read -r -p "Proceed with renumbering? (yes/no): " answer
    if [[ "$answer" =~ ^[Yy]es$ ]]; then
        break
    elif [[ "$answer" =~ ^[Nn]o$ ]]; then
        echo "Operation cancelled."
        exit 0
    else
        echo "Please answer yes or no."
    fi
done

tmp_names=()
for i in "${!valid[@]}"; do
    tmp=".tmp_renumber_$$_$i"
    if [[ -e "$tmp" ]]; then
        echo "Error: temporary name $tmp already exists. Aborting."
        exit 1
    fi
    tmp_names+=("$tmp")
done

for i in "${!valid[@]}"; do
    mv -- "${valid[$i]}" "${tmp_names[$i]}"
    show_progress $((i+1)) ${#valid[@]}
done
echo

for i in "${!valid[@]}"; do
    mv -- "${tmp_names[$i]}" "${new_names[$i]}"
    show_progress $((i+1)) ${#valid[@]}
done
echo

echo "Done."
