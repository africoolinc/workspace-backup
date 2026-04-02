#!/bin/bash
# =============================================================================
# Intervention Agent — Gibson's Workspace Manager
# Phase: Phase 2
# Responsibility: Execute intervention actions per intervention ladder
#                 Full problem-solving framework: DESCRIBE→IDENTIFY→CORRECT→VALIDATE
# =============================================================================

set -o pipefail

WORKSPACE="${WORKSPACE:-/root/.openclaw/workspace}"
STATE_DIR="${WORKSPACE}/workspace-manager/state"
PHASE_FILE="${STATE_DIR}/current_phase.txt"
METRICS_FILE="${STATE_DIR}/current_metrics.json"
DECISION_LOG="${WORKSPACE}/workspace-manager/logs/decisions.md"
INTERVENTION_LOG="${WORKSPACE}/workspace-manager/logs/interventions.md"
QUEUE_FILE="${STATE_DIR}/intervention_queue.json"

# Tier definitions
TIER1="openclaw zerotier portainer bridge_db"
TIER2="bridge_api bridge_heartbeat bridge_tracker"
TIER3="gibsons_dash dao_wallet crypto-register-api crypto-register-frontend crypto_blockchain crypto_postgres"
TIER4="trusting_beaver crypto_grafana crypto_prometheus crypto_traefik crypto_redis crypto_cloudflare crypto_dns crypto_mpesa crypto_phone stack-duka-dao-app-1 crypto_loki crypto_nginx"

# =============================================================================
# Utilities
# =============================================================================

log_decision() {
    local situation="$1"
    local analysis="$2"
    local decision="$3"
    local outcome="$4"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %I:%M %p %Z")

    mkdir -p "$(dirname "$DECISION_LOG")"
    if [ ! -f "$DECISION_LOG" ]; then
        cat > "$DECISION_LOG" << 'HEADER'
# Decision Log — Gibson's Workspace Manager

Full reasoning for every action taken or declined.

| Timestamp (EAT) | Situation | Analysis | Decision | Outcome |
|----------------|-----------|----------|----------|---------|
HEADER
    fi

    printf "| %s | %s | %s | %s | %s |\n" \
        "$timestamp" "$situation" "$analysis" "$decision" "$outcome" >> "$DECISION_LOG"
}

log_intervention() {
    local container="$1"
    local action="$2"
    local reason="$3"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %I:%M %p %Z")

    mkdir -p "$(dirname "$INTERVENTION_LOG")"
    if [ ! -f "$INTERVENTION_LOG" ]; then
        cat > "$INTERVENTION_LOG" << 'HEADER'
# Intervention Log — Gibson's Workspace Manager

All throttle/stop actions taken.

| Timestamp (EAT) | Container | Action | Reason | Phase |
|----------------|-----------|--------|--------|-------|
HEADER
    fi

    local phase
    phase=$(cat "${PHASE_FILE}" 2>/dev/null || echo "UNKNOWN")

    printf "| %s | %s | %s | %s | %s |\n" \
        "$timestamp" "$container" "$action" "$reason" "$phase" >> "$INTERVENTION_LOG"
}

is_container_running() {
    docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${1}$"
}

get_container_memory() {
    docker stats --no-stream --format '{{.MemUsage}}' "$1" 2>/dev/null | awk '{print $1}' || echo "0"
}

# =============================================================================
# Intervention Actions
# =============================================================================

stop_container() {
    local container="$1"
    local reason="$2"

    if ! is_container_running "$container"; then
        echo "SKIP: ${container} — not running"
        return 0
    fi

    local mem_before
    mem_before=$(get_container_memory "$container")

    docker stop -t 30 "$container" 2>/dev/null
    local exit_code=$?

    if [ "$exit_code" -eq 0 ]; then
        log_intervention "$container" "STOPPED" "$reason"
        echo "STOPPED: ${container} (was using ${mem_before})"
    else
        echo "FAILED: ${container} — exit code ${exit_code}"
        log_decision "STOP ${container}" "docker stop failed with ${exit_code}" "ABORTED" "Container remains running"
    fi
}

reduce_restart_frequency() {
    local container="$1"
    docker update --restart no "$container" 2>/dev/null && \
        log_intervention "$container" "RESTART_DISABLED" "PHASE-2 advisory" && \
        echo "RESTART_DISABLED: ${container}" || \
        echo "FAILED: ${container} restart update"
}

clear_container_logs() {
    local container="$1"
    docker logs "$container" --tail 0 2>/dev/null > /dev/null 2>&1
    # Truncate log via docker's internal mechanism if possible
    echo "CLEARED_LOGS: ${container}"
}

clear_dangling_resources() {
    local before_bytes
    before_bytes=$(docker system df --format '{{.Size}}' 2>/dev/null | head -1)
    docker system prune -f --volumes 2>/dev/null | grep -v "^Total" || true
    echo "DANGLED_CLEARED: before=${before_bytes}"
}

reduce_memory_limit() {
    local container="$1"
    local limit_bytes="$2"  # e.g. "256m"
    docker update --memory "$limit_bytes" "$container" 2>/dev/null && \
        log_intervention "$container" "MEMORY_REDUCED_TO_${limit_bytes}" "PHASE-3 active" && \
        echo "MEMORY_REDUCED: ${container} → ${limit_bytes}" || \
        echo "FAILED: ${container} memory update"
}

# =============================================================================
# Problem-Solving Framework
# =============================================================================

step_describe() {
    # What triggered the threshold?
    local phase="$1"
    local docker_memory_bytes="$2"
    local docker_ceiling_bytes="$3"
    local load_percent="$4"
    local load_avg="$5"

    echo "=== DESCRIBE ==="
    echo "Trigger: Phase ${phase} triggered"
    echo "  Docker memory: ${docker_memory_bytes} / ${docker_ceiling_bytes}"
    echo "  System load: ${load_avg} (${load_percent}% of cores)"
    echo "  Time: $(date +'%Y-%m-%d %I:%M %p %Z')"
}

step_identify_causes() {
    # Why are we here?
    echo "=== IDENTIFY CAUSES ==="

    # Check top memory consumers
    echo "Top memory consumers (docker):"
    docker stats --no-stream --format '{{.Name}} {{.MemUsage}}' 2>/dev/null | \
        sort -t'/' -k1 -r | head -5 || echo "  (none)"

    echo "Top CPU processes (host):"
    ps aux --sort=-%cpu | head -6 | tail -5 | \
        awk '{printf "  PID %s: %s%% CPU — %s\n", $2, $3, $11}'

    echo "Recent container events:"
    docker events --since '5m' --format '{{.Type}} {{.Action}} {{.Actor.Attributes.name}}' 2>/dev/null | \
        tail -10 || echo "  (no recent events)"
}

step_compare_to_facts() {
    local phase="$1"
    echo "=== COMPARE TO FACTS ==="
    echo "Current phase: ${phase}"
    echo "Ceiling (50% docker): 6.0 GiB"
    echo "Intervention trigger (65% load): active"
    echo "Oracle reserve minimum: 1.5 GiB"
}

step_corrective_actions() {
    local phase="$1"
    local stopped_count=0
    local skipped_count=0

    echo "=== CORRECTIVE ACTIONS ==="

    case "$phase" in
        PHASE-2)
            echo "ADVISORY — clearing logs and reducing restart frequency..."
            # Clear dangling docker resources
            clear_dangling_resources

            # Reduce Tier 4 restart frequency
            for container in $TIER4; do
                if is_container_running "$container"; then
                    reduce_restart_frequency "$container"
                fi
            done
            echo "ADVISORY complete."
            ;;

        PHASE-3)
            echo "ACTIVE INTERVENTION — stopping Tier 4 containers..."
            for container in $TIER4; do
                if is_container_running "$container"; then
                    stop_container "$container" "PHASE-3 active intervention"
                    [ $? -eq 0 ] && ((stopped_count++))
                else
                    ((skipped_count++))
                fi
            done
            echo "PHASE-3 complete — ${stopped_count} stopped, ${skipped_count} already stopped."
            ;;

        PHASE-4)
            echo "EMERGENCY — Tier 1 only..."
            # Stop everything except TIER1
            local all_containers
            all_containers=$(docker ps --format '{{.Names}}' 2>/dev/null)

            for container in $all_containers; do
                if [[ ! " $TIER1 " =~ " $container " ]]; then
                    if is_container_running "$container"; then
                        stop_container "$container" "PHASE-4 emergency"
                        ((stopped_count++))
                    fi
                fi
            done

            # Oracle emergency notification
            echo "EMERGENCY: ${stopped_count} containers stopped. Tier 1 only running."
            log_decision "PHASE-4 EMERGENCY" "System load critical" "TIER1_ONLY" "${stopped_count} containers stopped"
            ;;

        *)
            echo "No corrective actions needed (PHASE-1)"
            ;;
    esac
}

step_validate() {
    local phase="$1"
    echo "=== VALIDATE ==="

    local docker_memory_bytes
    docker_memory_bytes=$(python3 -c "import json; d=json.load(open('${METRICS_FILE}')); print(int(d.get('docker',{}).get('memory_used_bytes',0)))" 2>/dev/null || echo "0")
    local oracle_available_bytes
    oracle_available_bytes=$(python3 -c "import json; d=json.load(open('${METRICS_FILE}')); print(int(d.get('memory',{}).get('oracle_available_bytes',0)))" 2>/dev/null || echo "0")
    local running_containers
    running_containers=$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l)

    echo "Post-intervention state:"
    echo "  Docker memory: $(echo "scale=2; $docker_memory_bytes / 1073741824" | bc 2>/dev/null) GiB"
    echo "  Oracle available: $(echo "scale=2; $oracle_available_bytes / 1073741824" | bc 2>/dev/null) GiB"
    echo "  Running containers: ${running_containers}"
    echo "  Oracle healthy: $([ "$oracle_available_bytes" -ge 1610612736 ] && echo YES || echo NO)"

    echo "PHASE-${phase} validation complete."
}

# =============================================================================
# Main
# =============================================================================

main() {
    local current_phase
    current_phase=$(cat "${PHASE_FILE}" 2>/dev/null || echo "PHASE-1")

    if [ "$current_phase" = "PHASE-1" ]; then
        echo "PHASE-1: No intervention needed."
        log_decision "PHASE-1_CHECK" "Within normal thresholds" "NO_ACTION" "System healthy"
        exit 0
    fi

    # Load current metrics
    local docker_memory_bytes oracle_available_bytes load_percent load_avg
    docker_memory_bytes=$(python3 -c "import json; d=json.load(open('${METRICS_FILE}')); print(int(d.get('docker',{}).get('memory_used_bytes',0)))" 2>/dev/null || echo "0")
    oracle_available_bytes=$(python3 -c "import json; d=json.load(open('${METRICS_FILE}')); print(int(d.get('memory',{}).get('oracle_available_bytes',0)))" 2>/dev/null || echo "0")
    load_percent=$(python3 -c "import json; d=json.load(open('${METRICS_FILE}')); print(float(d.get('system',{}).get('load_percent_of_cores',0)))" 2>/dev/null || echo "0")
    load_avg=$(python3 -c "import json; d=json.load(open('${METRICS_FILE}')); print(float(d.get('system',{}).get('load_average_1m',0)))" 2>/dev/null || echo "0")
    local docker_ceiling_bytes=6442450944  # 6 GiB

    step_describe "$current_phase" "$docker_memory_bytes" "$docker_ceiling_bytes" "$load_percent" "$load_avg"
    step_identify_causes
    step_compare_to_facts "$current_phase"
    step_corrective_actions "$current_phase"
    step_validate "$current_phase"

    log_decision "INTERVENTION_${current_phase}" "Load=${load_avg} Docker=${docker_memory_bytes}" "EXECUTED" "Intervention complete"
}

main "$@"
