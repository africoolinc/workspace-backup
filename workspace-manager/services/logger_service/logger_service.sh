#!/bin/bash
# =============================================================================
# Logger Service — Gibson's Workspace Manager
# Phase: Phase 2
# Responsibility: Structured append-only logging with async buffer + flush
#                 GZIP compression for archived logs
# =============================================================================

set -o pipefail

WORKSPACE="${WORKSPACE:-/root/.openclaw/workspace}"
LOG_DIR="${WORKSPACE}/workspace-manager/logs"
ARCHIVE_DIR="${LOG_DIR}/archive"
BUFFER_FILE="/tmp/workspace_manager_log_buffer.txt"
FLUSH_INTERVAL=30
LOGROTATE_SIZE_KB=5120
LOGROTATE_COUNT=10

# =============================================================================
# Log Functions
# =============================================================================

log_info() {
    local component="$1"
    local message="$2"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "[${timestamp}] [INFO] [${component}] ${message}" >> "${BUFFER_FILE}"
}

log_warn() {
    local component="$1"
    local message="$2"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "[${timestamp}] [WARN] [${component}] ${message}" >> "${BUFFER_FILE}"
}

log_error() {
    local component="$1"
    local message="$2"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "[${timestamp}] [ERROR] [${component}] ${message}" >> "${BUFFER_FILE}"
}

log_phase_change() {
    local from_phase="$1"
    local to_phase="$2"
    local trigger="$3"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %I:%M %p %Z")
    echo "[${timestamp}] [PHASE_CHANGE] ${from_phase} → ${to_phase} | Trigger: ${trigger}" >> "${BUFFER_FILE}"
}

# =============================================================================
# Flush Buffer to Disk (async-capable)
# =============================================================================

flush_buffer() {
    if [ ! -f "${BUFFER_FILE}" ] || [ ! -s "${BUFFER_FILE}" ]; then
        return 0
    fi

    mkdir -p "${LOG_DIR}"
    local timestamp
    timestamp=$(date +"%Y-%m-%d")

    # Rotate if current log is large
    local current_log="${LOG_DIR}/service_${timestamp}.log"
    if [ -f "$current_log" ]; then
        local size_kb
        size_kb=$(du -k "$current_log" | awk '{print $1}')
        if [ "$size_kb" -ge "$LOGROTATE_COUNT" ]; then
            mv "$current_log" "${current_log}.rotating"
        fi
    fi

    cat "${BUFFER_FILE}" >> "$current_log"
    : > "${BUFFER_FILE}"
    echo "Logger: Flushed $(wc -l < "$current_log") lines to ${current_log}"
}

# =============================================================================
# Archive Old Logs (GZIP)
# =============================================================================

archive_old_logs() {
    mkdir -p "${ARCHIVE_DIR}"
    local cutoff_date
    cutoff_date=$(date -d "7 days ago" +%Y-%m-%d)

    find "${LOG_DIR}" -name "*.log.*.rotating" -type f 2>/dev/null | while read -r log_file; do
        local file_date
        file_date=$(echo "$log_file" | grep -oP '\d{4}-\d{2}-\d{2}' | tail -1)
        if [[ "$file_date" < "$cutoff_date" ]]; then
            gzip -9 "$log_file" && mv "${log_file}.gz" "${ARCHIVE_DIR}/"
            echo "Archived: ${log_file}.gz"
        fi
    done
}

# =============================================================================
# Structured Log Entry (for metrics pipeline)
# =============================================================================

log_metric_entry() {
    local metric_name="$1"
    local metric_value="$2"
    local unit="$3"
    local tags="$4"
    local timestamp
    timestamp=$(date -u +%s%3N)  # milliseconds

    echo "metric=${metric_name} value=${metric_value} unit=${unit} tags=${tags} time=${timestamp}" >> "${LOG_DIR}/metrics_pipeline.log"
}

# =============================================================================
# Rotate Large Log Files
# =============================================================================

rotate_log() {
    local log_file="$1"
    if [ ! -f "$log_file" ]; then
        return 0
    fi

    local size_kb
    size_kb=$(du -k "$log_file" 2>/dev/null | awk '{print $1}' || echo 0)

    if [ "$size_kb" -ge "$LOGROTATE_SIZE_KB" ]; then
        local rotated="${log_file}.$(date +%Y%m%d_%H%M%S)"
        cp "$log_file" "$rotated"
        : > "$log_file"
        gzip -9 "$rotated" &
        echo "Rotated: ${log_file} → ${rotated}.gz"
    fi
}

# =============================================================================
# Init Buffer
# =============================================================================

init() {
    mkdir -p "$(dirname "${BUFFER_FILE}")"
    touch "${BUFFER_FILE}"
    echo "Logger service initialized. Buffer: ${BUFFER_FILE}"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local command="${1:-status}"

    case "$command" in
        flush)
            flush_buffer
            ;;
        archive)
            archive_old_logs
            ;;
        rotate)
            rotate_log "${LOG_DIR}/metrics.md"
            rotate_log "${LOG_DIR}/decisions.md"
            rotate_log "${LOG_DIR}/interventions.md"
            ;;
        info|warn|error|phase)
            init
            ;;
        status)
            echo "Logger Service Status:"
            echo "  Buffer: ${BUFFER_FILE} ($(wc -l < "${BUFFER_FILE}" 2>/dev/null || echo 0) lines)"
            echo "  Archive dir: ${ARCHIVE_DIR}"
            echo "  Flush interval: ${FLUSH_INTERVAL}s"
            echo "  Logrotate size: ${LOGROTATE_SIZE_KB} KB"
            ;;
        *)
            echo "Usage: $0 {flush|archive|rotate|status}"
            ;;
    esac
}

main "$@"
