#!/bin/bash
set -euo pipefail

STATE_DIR="/var/lib/initramfs-test"
STATE_FILE="$STATE_DIR/state.json"
RESULTS_DIR="$STATE_DIR/results"
INITRAMFS_CONF="/etc/initramfs-tools/initramfs.conf"
CRON_FILE="/etc/cron.d/initramfs-bench"

ALGORITHMS=("gzip" "bzip2" "lz4" "lzma" "lzop" "xz" "zstd")
RUNS=30

mkdir -p "$STATE_DIR" "$RESULTS_DIR"

log() {
    echo "$@" | logger -t initramfs-bench
    echo "$@"
}

init_state() {
    cat >"$STATE_FILE" <<EOF
{
  "algorithm_index": 0,
  "run_count": 0
}
EOF
}

read_state() {
    if [[ -f "$STATE_FILE" ]]; then
        ALGO_INDEX=$(jq .algorithm_index "$STATE_FILE")
        RUN_COUNT=$(jq .run_count "$STATE_FILE")
    else
        init_state
        ALGO_INDEX=0
        RUN_COUNT=0
    fi
}

write_state() {
    jq -n \
       --argjson idx "$ALGO_INDEX" \
       --argjson run "$RUN_COUNT" \
       '{algorithm_index: $idx, run_count: $run}' \
       > "$STATE_FILE"
}

update_initramfs_conf() {
    local algo=$1
    sudo sed -i -E "s/^COMPRESS=.*/COMPRESS=$algo/" "$INITRAMFS_CONF"
    log "Rebuilding initramfs with $algo..."
    sudo update-initramfs -u -k all
}

log_results() {
    local algo=$1
    {
        echo "===== Run $((RUN_COUNT+1)) with $algo ====="
        date
        systemd-analyze
        systemd-analyze blame
        echo
    } >> "$RESULTS_DIR/${algo}_boot.txt"
    log "Logged results for $algo run $((RUN_COUNT+1))"
}

disable_cron() {
    if [[ -f "$CRON_FILE" ]]; then
        log "Disabling cron job..."
        sudo rm -f "$CRON_FILE"
    fi
}

main() {
    read_state
    local algo=${ALGORITHMS[$ALGO_INDEX]}

    log_results "$algo"

    RUN_COUNT=$((RUN_COUNT+1))

    if (( RUN_COUNT >= RUNS )); then
        RUN_COUNT=0
        ALGO_INDEX=$((ALGO_INDEX+1))
        if (( ALGO_INDEX < ${#ALGORITHMS[@]} )); then
            algo=${ALGORITHMS[$ALGO_INDEX]}
            update_initramfs_conf "$algo"
        else
            log "All algorithms completed."
            rm -f "$STATE_FILE"
            disable_cron
            exit 0
        fi
    fi

    write_state

    log "Rebooting in 60 seconds (Ctrl+C to cancel)..."
    sleep 60
    systemctl reboot
}

main

