#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

COLORS=(
  green
  yellow
  cyan
  red
)

LOGS=()

for dir in 0 1 2 3; do
    log_dir="$HOME/.local/share/craftos-pc/computer/${dir}/logs"

    if [[ ! -d "$log_dir" ]]; then
        echo "Missing directory: $log_dir" >&2
        exit 1
    fi

    files=( "$log_dir"/TeleNet-$((dir + 1))-*.log )

    latest_file=$(
        printf '%s\n' "${files[@]}" | sort -V | tail -n 1
    )

    if [[ -z "$latest_file" ]]; then
        echo "No matching logs found in $log_dir" >&2
        exit 1
    fi

    LOGS+=("$latest_file")
done

echo "Opening logs:"
printf '  %s\n' "${LOGS[@]}"
echo

multitail -s 2 \
    -ci "${COLORS[0]}" "${LOGS[0]}" \
    -ci "${COLORS[1]}" "${LOGS[1]}" \
    -ci "${COLORS[2]}" "${LOGS[2]}" \
    -ci "${COLORS[3]}" "${LOGS[3]}"