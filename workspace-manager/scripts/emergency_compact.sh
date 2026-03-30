#!/bin/bash
# ============================================================
# Gibson's Workspace Manager — Emergency Compaction Script
# Stops Tier 4 containers to free memory under 30% ceiling.
# USE ONLY WHEN: Docker memory > 30% OR OpenClaw available < 1 GiB
# ============================================================
set -euo pipefail

WORKSPACE="/root/.openclaw/workspace"
INTERVENTIONS="${WORKSPACE}/workspace-manager/logs/interventions.md"
DECISIONS="${WORKSPACE}/workspace-manager/logs/decisions.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S GMT+3')

# Tier 4 containers (stop first — least business impact)
TIER4_CONTAINERS=(
    "crypto_redis"
    "crypto_traefik"
    "crypto_resolver"
    "crypto_prometheus"
    "stack-duka-dao-app-1"
    "trusting_beaver"
    "bridge-api-dev"
)

# Tier 3 containers (stop if Tier 4 insufficient)
TIER3_CONTAINERS=(
    "crypto-register-api"
    "crypto-register-frontend"
    "trading-api"
    "gibsons_dash"
    "dao_wallet"
)

# Tier 1 containers (NEVER STOP)
TIER1_CONTAINERS=(
    "portainer"
    "zerotier"
)

echo "=============================================="
echo "  Gibson's Workspace Manager — Emergency Compaction"
echo "  ${TIMESTAMP}"
echo "=============================================="
echo ""
echo "⚠ This will stop non-essential containers."
echo ""

# Check if running as correct user / permissions
if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker not accessible. Aborting."
    exit 1
fi

STOPPED_COUNT=0
STOPPED_LIST=""

# Stop Tier 4 containers
echo "--- Stopping Tier 4 Containers ---"
for container in "${TIER4_CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo "Stopping: ${container}"
        if docker stop "${container}" >/dev/null 2>&1; then
            echo "  ✅ ${container} stopped"
            STOPPED_COUNT=$((STOPPED_COUNT + 1))
            STOPPED_LIST="${STOPPED_LIST} ${container}"
        else
            echo "  ❌ Failed to stop ${container}"
        fi
    else
        echo "  (not running): ${container}"
    fi
done

# If still over ceiling, stop Tier 3
if [[ ${STOPPED_COUNT} -eq 0 ]]; then
    echo ""
    echo "--- Stopping Tier 3 Containers ---"
    for container in "${TIER3_CONTAINERS[@]}"; do
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            echo "Stopping: ${container}"
            if docker stop "${container}" >/dev/null 2>&1; then
                echo "  ✅ ${container} stopped"
                STOPPED_COUNT=$((STOPPED_COUNT + 1))
                STOPPED_LIST="${STOPPED_LIST} ${container}"
            else
                echo "  ❌ Failed to stop ${container}"
            fi
        fi
    done
fi

echo ""
echo "=============================================="
echo "  Compaction Complete"
echo "=============================================="
echo ""
echo "Stopped ${STOPPED_COUNT} container(s):${STOPPED_LIST}"
echo ""

# Log to interventions
{
    echo "| ${TIMESTAMP} | EMERGENCY COMPACTION | docker stop |${STOPPED_LIST} | SUCCESS | Unknown | Auto-compaction via emergency_compact.sh |"
} >> "${INTERVENTIONS}"

# Show remaining containers
echo "Remaining containers:"
docker stats --no-stream --format "  {{.Name}}\t{{.MemUsage}}" 2>/dev/null || echo "  (unable to list)"

echo ""
echo "Logged to: ${INTERVENTIONS}"
echo "=============================================="
