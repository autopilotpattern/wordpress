#!/bin/bash
set -e

help() {
    echo 'Uses cli tools free and top to determine current CPU and memory usage'
    echo 'for the telemetry service.'
}

# memory usage in percent
memory() {
    # awk oneliner to get memory usage
    # free -m | awk 'NR==2{printf "Memory Usage: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }'
    # output:
    # Memory Usage: 15804/15959MB (99.03%)
    (>&2 echo "memory check fired")
    local memory=$(free -m | awk 'NR==2{printf "%.2f", $3*100/$2 }')
    echo ${memory}
}

# cpu load
cpu() {
    # oneliner to display cpu load
    # top -bn1 | grep load | awk '{printf "CPU Load: %.2f\n", $(NF-2)}'
    (>&2 echo "cpu check fired")
    local cpuload=$(top -bn1 | grep load | awk '{printf "%.2f", $(NF-2)}')
    echo ${cpuload}
}

cmd=$1
if [ ! -z "$cmd" ]; then
    shift 1
    $cmd "$@"
    exit
fi

help
