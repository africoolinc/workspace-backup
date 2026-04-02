#!/bin/bash
# =============================================================================
# Notifier Service — Gibson's Workspace Manager
# Phase: Phase 2
# Responsibility: Alert Gibson through Oracle (OpenClaw) when action is needed
#                 Severity levels: INFO → YELLOW → ORANGE → RED → CRITICAL
# =============================================================================

set -o pipefail

WORKSPACE="${WORKSPACE:-/root/.openclaw/workspace}"
STATE_DIR="${WORKSPACE}/workspace-manager/state"
METRICS_FILE="${STATE_DIR}/current_metrics.json"
PHASE_FILE="${STATE_DIR}/current_phase.txt"

# Severity thresholds
SEVERITY_PHASE1="INFO"
SEVERITY_PHASE2="YELLOW"
SEVERITY_PHASE3="ORANGE"
SEVERITY_PHASE4="RED"
SEVERITY_EMERGENCY="CRITICAL"

# =============================================================================
# Compose Alert Message
# =============================================================================

compose_alert() {
    local severity="$1"
    local phase="$2"
    local docker_mem_gib="$3"
    local load_avg="$4"
    local load_percent="$5"
    local oracle_avail_gib="$6"
    local containers_running="$7"
    local stopped_count="$8"
    local docker_percent="$9"

    local emoji
    case "$severity" in
        INFO) emoji="ℹ️" ;;
        YELLOW) emoji="🟡" ;;
        ORANGE) emoji="🟠" ;;
        RED) emoji="🔴" ;;
        CRITICAL) emoji="🚨" ;;
        *) emoji="⚪" ;;
    esac

    cat << EOF
${emoji} **Workspace Manager Alert — ${severity}**

**Phase:** ${phase}
**Time:** $(date +"%Y-%m-%d %I:%M %p %Z")

**System State:**
- Docker Memory: ${docker_mem_gib} GiB / 6.0 GiB ceiling (${docker_percent}%)
- System Load: ${load_avg} (${load_percent}% of 4 cores)
- Oracle Available: ${oracle_avail_gib} GiB
- Containers Running: ${containers_running}

**Action Taken:** $([ "$stopped_count" -gt 0 ] && echo "Stopped ${stopped_count} containers" || echo "Monitoring only")

EOF
}

compose_daily_summary() {
    local phase="$1"
    local avg_load="$2"
    local max_load="$3"
    local avg_docker_mem="$4"
    local intervention_count="$5"
    local uptime_days="$6"

    cat << EOF
**Workspace Manager — Daily Summary**

**Date:** $(date +"%Y-%m-%d")
**Phase:** ${phase}
**System Uptime:** ${uptime_days} days

**Load Average:** avg=${avg_load} | max=${max_load}
**Docker Memory:** avg=${avg_docker_mem} GiB

**Interventions Today:** ${intervention_count}
**Oracle:** Healthy

EOF
}

# =============================================================================
# Alert via Oracle (write to file, Oracle picks it up)
# =============================================================================

notify_oracle() {
    local severity="$1"
    local message="$2"
    local alert_file="${WORKSPACE}/workspace-manager/.pending_alert.json"

    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    cat > "$alert_file" << EOF
{
  "alert": true,
  "severity": "${severity}",
  "source": "workspace_manager",
  "timestamp": "${timestamp}",
  "message": ${message}
}
EOF

    echo "[notifier] Alert filed: ${severity} — ${alert_file}"
}

# =============================================================================
# Notify Gibson (called from Oracle context — writes to HEARTBEAT context)
# =============================================================================

notify_gibson() {
    local severity="$1"
    local message="$2"

    # For now, write to a dedicated notifier log that Oracle reads on next heartbeat
    local notifier_log="${WORKSPACE}/workspace-manager/logs/notifier_alerts.md"
    mkdir -p "$(dirname "$notifier_log")"

    local timestamp
    timestamp=$(date +"%Y-%m-%d %I:%M %p %Z")

    if [ ! -f "$notifier_log" ]; then
        cat > "$notifier_log" << 'HEADER'
# Notifier Alerts — Gibson's Workspace Manager

| Timestamp (EAT) | Severity | Message |
|----------------|----------|---------|
HEADER
    fi

    printf "| %s | %s | %s |\n" "$timestamp" "$severity" "$message" >> "$notifier_log"
    echo "[notifier] Gibson notified: ${severity} — ${message}"
}

# =============================================================================
# Emergency Alert (triggers immediate Oracle attention)
# =============================================================================

emergency_alert() {
    local docker_mem_gib="$1"
    local load_avg="$2"
    local oracle_avail_gib="$3"
    local containers_running="$4"
    local stopped_count="$5"
    local docker_percent="$6"
    local load_percent="$7"

    local message
    message=$(compose_alert "CRITICAL" "PHASE-4" "$docker_mem_gib" "$load_avg" "$load_percent" "$oracle_avail_gib" "$containers_running" "$stopped_count" "$docker_percent")

    notify_gibson "CRITICAL" "PHASE-4 triggered — ${load_avg} load, ${docker_mem_gib} GiB docker, ${oracle_avail_gib} GiB Oracle free. ${stopped_count} containers stopped."
    notify_oracle "CRITICAL" "$message"

    echo "[EMERGENCY] PHASE-4 alert dispatched to Oracle + Gibson"
}

# =============================================================================
# Phase Change Alert
# =============================================================================

alert_phase_change() {
    local from_phase="$1"
    local to_phase="$2"
    local trigger="$3"

    notify_gibson "$to_phase" "Phase change: ${from_phase} → ${to_phase} | Trigger: ${trigger}"

    echo "[notifier] Phase change alert: ${from_phase} → ${to_phase} (${trigger})"
}

# =============================================================================
# Daily Summary
# =============================================================================

send_daily_summary() {
    local phase="$1"
    local avg_load="$2"
    local max_load="$3"
    local avg_docker_mem="$4"
    local intervention_count="$5"
    local uptime_days="$6"

    local summary
    summary=$(compose_daily_summary "$phase" "$avg_load" "$max_load" "$avg_docker_mem" "$intervention_count" "$uptime_days")

    notify_gibson "INFO" "Daily Summary: Phase ${phase} | Avg load ${avg_load} | ${intervention_count} interventions today"

    echo "[notifier] Daily summary sent"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local command="$1"
    shift

    case "$command" in
        emergency)
            emergency_alert "$1" "$2" "$3" "$4" "$5" "$6" "$7"
            ;;
        phase_change)
            alert_phase_change "$1" "$2" "$3"
            ;;
        daily_summary)
            send_daily_summary "$1" "$2" "$3" "$4" "$5" "$6"
            ;;
        info|warn|critical)
            notify_gibson "$command" "$1"
            ;;
        status)
            echo "Notifier Service — Last 5 alerts:"
            tail -5 "${WORKSPACE}/workspace-manager/logs/notifier_alerts.md" 2>/dev/null || echo "(no alerts)"
            ;;
        *)
            echo "Usage: $0 {emergency|phase_change|daily_summary|info|warn|critical|status}"
            ;;
    esac
}

main "$@"
