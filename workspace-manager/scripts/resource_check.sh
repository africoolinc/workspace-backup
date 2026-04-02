#!/bin/bash
# =============================================================================
# Resource Check — Entry Point Script
# Gibson's Workspace Manager — Phase 2
#
# Full pipeline: resource_monitor → policy_engine → intervention_agent → notifier
# Run by: heartbeat cron (every 5 min)
#
# Usage: ./resource_check.sh [--dry-run]
# =============================================================================

set -o pipefail

WORKSPACE="${WORKSPACE:-/root/.openclaw/workspace}"
cd "${WORKSPACE}" 2>/dev/null

# Source all services
RESOURCE_MONITOR="${WORKSPACE}/workspace-manager/services/resource_monitor/resource_monitor.sh"
POLICY_ENGINE="${WORKSPACE}/workspace-manager/services/policy_engine/policy_engine.sh"
INTERVENTION_AGENT="${WORKSPACE}/workspace-manager/services/intervention_agent/intervention_agent.sh"
NOTIFIER="${WORKSPACE}/workspace-manager/services/notifier_service/notifier_service.sh"
LOGGER="${WORKSPACE}/workspace-manager/services/logger_service/logger_service.sh"

DRY_RUN=false
[ "$1" = "--dry-run" ] && DRY_RUN=true

# =============================================================================
# STEP 1 — Collect Metrics
# =============================================================================

echo "[resource_check] $(date +'%Y-%m-%d %I:%M %p %Z') — Starting resource check..."

"${RESOURCE_MONITOR}"
if [ $? -ne 0 ]; then
    echo "ERROR: resource_monitor failed"
    exit 1
fi

# Flush logger buffer after metric collection
"${LOGGER}" flush 2>/dev/null

# =============================================================================
# STEP 2 — Read previous phase BEFORE policy_engine overwrites it
# =============================================================================

PREV_PHASE=$(cat "${WORKSPACE}/workspace-manager/state/current_phase.txt" 2>/dev/null || echo "PHASE-1")

# =============================================================================
# STEP 3 — Evaluate Policy (writes new phase to current_phase.txt)
# =============================================================================

POLICY_OUTPUT=$("${POLICY_ENGINE}" 2>&1)
PHASE=$(echo "$POLICY_OUTPUT" | python3 -c \
    "import json,sys; d=json.load(sys.stdin); print(d.get('phase','PHASE-1'))" 2>/dev/null || echo "PHASE-1")

echo "[resource_check] Phase: ${PHASE} (was: ${PREV_PHASE})"

# =============================================================================
# STEP 4 — Notify on Phase Change
# =============================================================================

if [ "$PHASE" != "$PREV_PHASE" ] && [ "$PREV_PHASE" != "UNKNOWN" ]; then
    echo "[resource_check] PHASE CHANGE: ${PREV_PHASE} → ${PHASE}"
    "${NOTIFIER}" phase_change "${PREV_PHASE}" "${PHASE}" "load_or_memory_threshold"
fi

# =============================================================================
# STEP 4 — Intervention (if needed)
# =============================================================================

if [ "$PHASE" != "PHASE-1" ]; then
    echo "[resource_check] PHASE-${PHASE: -1}: Running intervention..."

    if [ "$DRY_RUN" = true ]; then
        echo "[resource_check] DRY RUN — skipping actual intervention"
    else
        "${INTERVENTION_AGENT}"
        INTERVENTION_EXIT=$?

        if [ $INTERVENTION_EXIT -ne 0 ]; then
            echo "WARN: intervention_agent returned ${INTERVENTION_EXIT}"
        fi
    fi

    # Flush logger after intervention
    "${LOGGER}" flush 2>/dev/null

    # Notify on PHASE-3+
    if [ "${PHASE}" = "PHASE-3" ] || [ "${PHASE}" = "PHASE-4" ]; then
        # Extract metrics for alert
        python3 -c "
import json
try:
    with open('${WORKSPACE}/workspace-manager/state/current_metrics.json') as f:
        d = json.load(f)
    docker_mem = d.get('docker',{}).get('memory_used_bytes',0)
    load_avg = d.get('system',{}).get('load_average_1m',0)
    load_pct = d.get('system',{}).get('load_percent_of_cores',0)
    oracle_avail = d.get('memory',{}).get('oracle_available_bytes',0)
    containers = d.get('docker',{}).get('container_count',0)
    docker_pct = d.get('docker',{}).get('usage_percent_of_ceiling',0)
    docker_gib = docker_mem / 1073741824
    oracle_gib = oracle_avail / 1073741824
    print(f'{docker_gib:.2f}|{load_avg}|{load_pct}|{oracle_gib:.2f}|{containers}|0|{docker_pct}')
except Exception as e:
    print('0|0|0|0|0|0|0')
" > /tmp/wm_alert_metrics.txt

        IFS='|' read -r docker_mem_gib load_avg load_pct oracle_avail_gib containers stopped docker_pct < /tmp/wm_alert_metrics.txt

        "${NOTIFIER}" emergency "${docker_mem_gib}" "${load_avg}" "${load_pct}" "${oracle_avail_gib}" "${containers}" "${stopped}" "${docker_pct}"
    fi
else
    echo "[resource_check] PHASE-1: No intervention needed."
fi

# =============================================================================
# STEP 5 — Final Flush
# =============================================================================

"${LOGGER}" flush 2>/dev/null
"${LOGGER}" rotate 2>/dev/null

echo "[resource_check] Complete — Phase: ${PHASE}"
