#!/bin/bash
# ============================================================
# Gibson's Workspace Manager — Resource Check Script
# Polls docker stats, evaluates against 30% ceiling policy,
# and recommends or takes intervention action.
# ============================================================
set -euo pipefail

WORKSPACE="/root/.openclaw/workspace"
RULES="${WORKSPACE}/WORKSPACE_RULES.md"
METRICS="${WORKSPACE}/workspace-manager/logs/metrics.md"
INTERVENTIONS="${WORKSPACE}/workspace-manager/logs/interventions.md"
DECISIONS="${WORKSPACE}/workspace-manager/logs/decisions.md"

# Config — from WORKSPACE_RULES.md (30% ceiling)
CEILING_PERCENT=30
SYSTEM_MEMORY_KIB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
SYSTEM_MEMORY_GIB=$(echo "scale=2; ${SYSTEM_MEMORY_KIB} / 1024 / 1024" | bc)
CEILING_GIB=$(echo "scale=2; ${SYSTEM_MEMORY_GIB} * ${CEILING_PERCENT} / 100" | bc)
WARNING_GIB=$(echo "scale=2; ${CEILING_GIB} * 0.93" | bc)  # 93% of ceiling = warning
SYSTEM_FREE_KIB=$(grep MemFree /proc/meminfo | awk '{print $2}')
SYSTEM_FREE_GIB=$(echo "scale=2; ${SYSTEM_FREE_KIB} / 1024 / 1024" | bc)
DOCKER_MEM_KIB=$(docker stats --no-stream --format '{{.MemUsage}}' | awk -F'MiB' '{sum+=$1} END {print sum * 1024}')
DOCKER_MEM_GIB=$(echo "scale=4; ${DOCKER_MEM_KIB} / 1024 / 1024" | bc)
DOCKER_PERCENT=$(echo "scale=2; ${DOCKER_MEM_GIB} / ${SYSTEM_MEMORY_GIB} * 100" | bc)

# Colors
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'

echo "=============================================="
echo "  Gibson's Workspace Manager — Resource Check"
echo "  $(date '+%Y-%m-%d %H:%M:%S GMT+3')"
echo "=============================================="
echo ""
echo "System Memory:  ${SYSTEM_MEMORY_GIB} GiB"
echo "Docker Ceiling: ${CEILING_GIB} GiB (${CEILING_PERCENT}%)"
echo "Docker Used:    ${DOCKER_MEM_GIB} GiB (${DOCKER_PERCENT}%)"
echo "System Free:    ${SYSTEM_FREE_GIB} GiB"
echo ""

# Evaluate status
STATUS="NORMAL"
if (( $(echo "${DOCKER_PERCENT} > ${CEILING_PERCENT}" | bc -l) )); then
    STATUS="CRITICAL"
    COLOR=${RED}
elif (( $(echo "${DOCKER_PERCENT} > 28" | bc -l) )); then
    STATUS="WARNING"
    COLOR=${YELLOW}
else
    STATUS="HEALTHY"
    COLOR=${GREEN}
fi

echo -e "${COLOR}[${STATUS}]${NC} Docker usage: ${DOCKER_PERCENT}% of ceiling"

# Detailed container table
echo ""
echo "Container Details:"
echo "------------------"
docker stats --no-stream --format "  {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}\t{{.MemPerc}}" 2>/dev/null || echo "  (docker stats unavailable)"

# Decision & logging
if [[ "${STATUS}" == "CRITICAL" ]]; then
    echo ""
    echo -e "${RED}⚠ CRITICAL — Above 30% ceiling! Intervention required.${NC}"
    echo "Review WORKSPACE_RULES.md intervention ladder."
    echo "Manual action: Run emergency_compact.sh or stop Tier 4 containers."
elif [[ "${STATUS}" == "WARNING" ]]; then
    echo ""
    echo -e "${YELLOW}⚠ WARNING — Approaching ceiling. Monitor closely.${NC}"
    echo "Consider stopping Tier 4 containers proactively."
else
    echo ""
    echo -e "${GREEN}✅ HEALTHY — Within normal parameters.${NC}"
fi

# Append to metrics log (last 5 entries only — rolling)
METRICS_ENTRY="| $(date '+%Y-%m-%d %H:%M') | ${DOCKER_MEM_GIB} GiB | ${DOCKER_PERCENT}% | $(echo "scale=0; ${DOCKER_PERCENT}/${CEILING_PERCENT}*100" | bc)% | ${STATUS} |"
echo "Last check: ${METRICS_ENTRY}" >> "${METRICS}.tmp" 2>/dev/null || true
tail -5 "${METRICS}.tmp" > "${METRICS}.new" 2>/dev/null || true
mv "${METRICS}.new" "${METRICS}" 2>/dev/null || true
rm -f "${METRICS}.tmp" 2>/dev/null || true

echo ""
echo "Logged to: ${METRICS}"
echo "=============================================="
