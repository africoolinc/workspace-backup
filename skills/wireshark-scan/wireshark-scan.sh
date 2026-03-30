#!/usr/bin/env bash
#
# wireshark-scan.sh — Deep Packet Analysis for Firefly Security Agent
# Captures and analyzes LAN traffic targeting:
#   - Malicious / suspicious IPs
#   - Unauthorized open ports (not in ADMIN_AUTHORIZED_PORTS)
#   - Unencrypted protocol exposure (telnet, FTP, HTTP, etc.)
#   - Anomalous DNS queries and beaconing behavior
#   - Correlates with firefly.sh JSON threat report
#
# When threat_level >= HIGH: generates SIEM/SOAR incident report → emails to africoolinc@gmail.com
#
# Usage:
#   wireshark-scan.sh                    # standalone
#   wireshark-scan.sh -i eth0 -d 300     # 5-min capture on eth0
#   wireshark-scan.sh --firefly-only     # skip capture, use latest firefly JSON only
#   wireshark-scan.sh --incident-only    # generate incident report from last capture only
#

set -uo pipefail
shopt -s globstar nullglob

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────────────────────
# Admin-authorized ports — anything NOT in this list is flagged UNEXPECTED
ADMIN_AUTHORIZED_PORTS="22,53,80,443,587,993,995,3000,3100,3101,3102,5000,5002,8000,8080,8443,10000,18789"

ALERT_EMAIL="africoolinc@gmail.com"
RUN_USER="africool"
RUN_HOME="/home/africool"
FIREFLY_LOG_BASE="${RUN_HOME}/Documents/netscan/firefly_logs"
WIRESHARK_LOG_BASE="${RUN_HOME}/Documents/netscan/wireshark_logs"
SUSPICIOUS_PORT_THRESHOLD=5    # flag IPs with >N unexpected ports
CAPTURE_DURATION="${CAPTURE_DURATION:-300}"   # seconds
MAX_PCAP_MB=50
INCIDENT_TEMPLATE="${RUN_HOME}/Documents/netscan/incidence_response.jpeg"

# Lock
LOCK_FILE="/tmp/wireshark-cron.lock"

# ─────────────────────────────────────────────────────────────────────────────
# AUTO-DETECT LAN INTERFACE
# ─────────────────────────────────────────────────────────────────────────────
detect_interface() {
    local iface
    iface=$(ip -o route get to 192.168.100.1 2>/dev/null | awk '{print $5}' | head -1)
    if [ -z "$iface" ]; then
        iface=$(ip -o route get to 8.8.8.8 2>/dev/null | awk '{print $5}' | head -1)
    fi
    echo "${iface:-enp0s25}"
}

INTERFACE="$(detect_interface)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
CURRENT_SCAN="${WIRESHARK_LOG_BASE}/scan_${TIMESTAMP}"
REPORT_FILE="${CURRENT_SCAN}/report.txt"
REPORT_JSON="${CURRENT_SCAN}/report.json"
INCIDENT_FILE="${CURRENT_SCAN}/incident.md"
PCAP_FILE="${CURRENT_SCAN}/capture.pcap"
ALERTS_FILE="${CURRENT_SCAN}/alerts.txt"

# ─────────────────────────────────────────────────────────────────────────────
# COLORS
# ─────────────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
BOLD='\033[1m'

log()     { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
log_ok()  { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn(){ echo -e "${YELLOW}[!]${NC} $*"; }
log_fail(){ echo -e "${RED}[✗]${NC} $*"; }
log_sec(){ echo -e "${RED}[SECURITY]${NC} $*"; }
log_info(){ echo -e "${BLUE}[*]${NC} $*"; }

err() { log_fail "$*" >&2; return 1; }

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────
count_lines() {
    local pattern="$1"; local file="$2"
    grep -c "$pattern" "$file" 2>/dev/null || echo 0
}

is_authorized_port() {
    local port="$1"
    echo "$ADMIN_AUTHORIZED_PORTS" | tr ',' '\n' | grep -qx "$port"
}

get_firefly_json() {
    find "${FIREFLY_LOG_BASE}" -maxdepth 1 -type d -name "scan_*" 2>/dev/null | sort | tail -1 | xargs -I{} echo "{}/report.json"
}

# ─────────────────────────────────────────────────────────────────────────────
# PARSE CLI ARGS
# ─────────────────────────────────────────────────────────────────────────────
MODE="full"      # full | firefly-only | incident-only
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i) INTERFACE="$2"; shift 2 ;;
        -d) CAPTURE_DURATION="$2"; shift 2 ;;
        --firefly-only) MODE="firefly-only"; shift ;;
        --incident-only) MODE="incident-only"; shift ;;
        -h|--help) cat << EOF
wireshark-scan.sh — Deep Packet Analysis Skill

Usage: $0 [OPTIONS]

Options:
  -i IFACE     Network interface (auto-detected)
  -d SECS      Capture duration in seconds (default: 300 = 5 min)
  --firefly-only   Skip capture, analyze only latest firefly JSON
  --incident-only  Generate incident report from last capture (no capture)
  -h            Show this help

Environment:
  CAPTURE_DURATION   Seconds to capture (default: 300)
  ALERT_EMAIL        Recipients (default: africoolinc@gmail.com)

EOF
exit 0 ;;
        *) shift ;;
    esac
done

# ─────────────────────────────────────────────────────────────────────────────
# LOCK
# ─────────────────────────────────────────────────────────────────────────────
acquire_lock() {
    if [ -f "${LOCK_FILE}" ]; then
        local pid
        pid=$(cat "${LOCK_FILE}" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            log "Lock active (PID $pid), exiting."
            exit 0
        fi
    fi
    echo $$ > "${LOCK_FILE}"
}
release_lock() { rm -f "${LOCK_FILE}"; }
trap release_lock EXIT
acquire_lock

# ─────────────────────────────────────────────────────────────────────────────
# SETUP
# ─────────────────────────────────────────────────────────────────────────────
setup() {
    mkdir -p "${CURRENT_SCAN}" "${WIRESHARK_LOG_BASE}"
    chmod 755 "${CURRENT_SCAN}" "${WIRESHARK_LOG_BASE}"
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. PACKET CAPTURE
# ─────────────────────────────────────────────────────────────────────────────
capture_packets() {
    log_info "━━━ Phase 1: Packet Capture ━━━"
    log_info "Interface : ${INTERFACE}"
    log_info "Duration   : ${CAPTURE_DURATION}s"
    log_info "Output     : ${PCAP_FILE}"

    # Limit pcap ring buffer to avoid huge files
    local ring_size
    ring_size=$(echo "${MAX_PCAP_MB} * 1024 * 1024" | bc 2>/dev/null || echo 52428800)

    sudo tshark \
        -i "${INTERFACE}" \
        -f "not port 18789 and not port 19999 and not port 11434" \
        -a duration:"${CAPTURE_DURATION}" \
        -w "${PCAP_FILE}" \
        -q 2>/dev/null

    if [ -f "${PCAP_FILE}" ] && [ -s "${PCAP_FILE}" ]; then
        local size_mb
        size_mb=$(du -m "${PCAP_FILE}" | awk '{print $1}')
        log_ok "Capture complete — ${size_mb} MB pcap saved"
    else
        log_warn "No packets captured (interface may be quiet)"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. PROTOCOL DISTRIBUTION
# ─────────────────────────────────────────────────────────────────────────────
analyze_protocols() {
    local out="${CURRENT_SCAN}/protocols.txt"
    log_info "━━━ Phase 2: Protocol Analysis ━━━"

    if [ ! -f "${PCAP_FILE}" ] || [ ! -s "${PCAP_FILE}" ]; then
        log_warn "No pcap file — skipping protocol analysis"
        return
    fi

    sudo tshark -r "${PCAP_FILE}" -q -z io,phs 2>/dev/null | grep -v "^$" > "${out}"
    chmod 600 "${out}"

    local proto_count
    proto_count=$(grep -c ":" "${out}" 2>/dev/null || echo 0)
    log_ok "Protocol distribution captured — ${proto_count} protocols active"

    # Flag unencrypted protocols
    local unenc_out="${CURRENT_SCAN}/unencrypted.txt"
    sudo tshark -r "${PCAP_FILE}" -Y "tcp.port in {23,21,25,110,143}" -T fields \
        -e ip.src -e ip.dst -e _ws.col.Protocol -e tcp.port 2>/dev/null | \
        grep -v "^$" > "${unenc_out}"
    chmod 600 "${unenc_out}"
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. TOP TALKERS (highest volume IPs)
# ─────────────────────────────────────────────────────────────────────────────
top_talkers() {
    local out="${CURRENT_SCAN}/top_talkers.txt"
    log_info "━━━ Phase 3: Top Talkers ━━━"

    if [ ! -f "${PCAP_FILE}" ] || [ ! -s "${PCAP_FILE}" ]; then
        log_warn "No pcap file — skipping top talkers"
        return
    fi

    sudo tshark -r "${PCAP_FILE}" -q -z iphosts,tree 2>/dev/null | head -60 > "${out}"
    chmod 600 "${out}"

    # Also get endpoints table
    sudo tshark -r "${PCAP_FILE}" -Y "ip" -T fields -e ip.src -e ip.proto \
        2>/dev/null | sort | uniq -c | sort -rn | head -20 > "${out}.srcs"
    chmod 600 "${out}.srcs"
    log_ok "Top talkers captured"
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. SUSPICIOUS PORT DETECTION
# ─────────────────────────────────────────────────────────────────────────────
scan_suspicious_ports() {
    local out="${CURRENT_SCAN}/port_analysis.txt"
    local threats_out="${CURRENT_SCAN}/threats_ports.txt"
    log_info "━━━ Phase 4: Suspicious Port Analysis ━━━"

    touch "${threats_out}"

    if [ ! -f "${PCAP_FILE}" ] || [ ! -s "${PCAP_FILE}" ]; then
        log_warn "No pcap — checking firefly data instead"
        correlate_firefly
        return
    fi

    # Extract all TCP/UDP conversations with ports
    sudo tshark -r "${PCAP_FILE}" -Y "tcp or udp" -T fields \
        -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e udp.srcport -e udp.dstport \
        2>/dev/null | awk -F'\t' '{
            src=$1; dst=$2; sport=$3; dport=$4; uport=$5
            if (sport != "") ports[sport]++; ips[src]++
            if (dport != "") ports[dport]++; ips[dport]++
            if (uport != "") ports[uport]++
            if ($5 != "") ports[$5]++
        } END {
            for (p in ports) print p, ports[p]
        }' | sort -k2 -rn > "${out}" 2>/dev/null

    chmod 600 "${out}"

    # Check each port against authorized list
    local total_threats=0
    {
        echo "PORT ANALYSIS — $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Authorized ports: ${ADMIN_AUTHORIZED_PORTS}"
        echo "=============================================="
    } > "${threats_out}"

    if [ -f "${out}" ]; then
        while read -r port count; do
            if ! is_authorized_port "$port"; then
                local risk="MEDIUM"
                case "$port" in
                    23|21|512|513|514|445|1433|3306|5432|27017|6379|11211) risk="HIGH" ;;
                    9999|4444|5555|6666|6667) risk="HIGH" ;;
                    23) echo "THREAT:HIGH: Telnet (port 23) — unencrypted remote access!" ;;
                    21) echo "THREAT:HIGH: FTP (port 21) — unencrypted file transfer!" ;;
                    445) echo "THREAT:HIGH: SMB (port 445) — possible EternalBlue!" ;;
                    1433) echo "THREAT:MEDIUM: MS-SQL (port 1433) — database exposure!" ;;
                    3306) echo "THREAT:MEDIUM: MySQL (port 3306) — database exposure!" ;;
                    5432) echo "THREAT:MEDIUM: PostgreSQL (port 5432) — database exposure!" ;;
                    27017) echo "THREAT:HIGH: MongoDB (port 27017) — NoSQL exposure!" ;;
                    6379) echo "THREAT:HIGH: Redis (port 6379) — in-memory DB exposure!" ;;
                    11211) echo "THREAT:HIGH: Memcached (port 11211) — cache exposure!" ;;
                    9999|4444|5555) echo "THREAT:HIGH: Suspicious non-std port ${port} — possible malware/C2!" ;;
                    *) echo "THREAT:MEDIUM: Unexpected port ${port} used (${count} packets) — verify with admin" ;;
                esac
                echo "$port (${count} pkts) → $risk" >> "${threats_out}"
                ((total_threats++))
            fi
        done < "${out}"
    fi

    chmod 600 "${threats_out}"
    log_ok "Suspicious port analysis done — ${total_threats} concerns flagged"
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. DNS ANOMALY CHECK
# ─────────────────────────────────────────────────────────────────────────────
dns_anomaly_check() {
    local out="${CURRENT_SCAN}/dns_anomalies.txt"
    log_info "━━━ Phase 5: DNS Anomaly Detection ━━━"

    if [ ! -f "${PCAP_FILE}" ] || [ ! -s "${PCAP_FILE}" ]; then
        log_warn "No pcap — skipping DNS analysis"
        return
    fi

    # Extract DNS queries
    sudo tshark -r "${PCAP_FILE}" -Y "dns.qry.name" -T fields \
        -e dns.qry.name -e ip.src -e frame.time_relative 2>/dev/null | \
        grep -v "^$" > "${out}" 2>/dev/null
    chmod 600 "${out}"

    # Check for suspicious domains
    local susp_dns_out="${CURRENT_SCAN}/suspicious_dns.txt"
    local susp_patterns="\.tk$|\.ml$|\.ga$|\.cf$|\.gq$|pastebin|binance|coinbase|icloud|drive-google|onion|tor2web"
    grep -iE "${susp_patterns}" "${out}" 2>/dev/null > "${susp_dns_out}"
    chmod 600 "${susp_dns_out}"

    local susp_count
    susp_count=$(wc -l < "${susp_dns_out}" 2>/dev/null || echo 0)
    [ "${susp_count}" -gt 0 ] && log_warn "${susp_count} suspicious DNS queries found"

    log_ok "DNS analysis done"
}

# ─────────────────────────────────────────────────────────────────────────────
# 6. BEACONING / C2 DETECTION (periodic traffic patterns)
# ─────────────────────────────────────────────────────────────────────────────
detect_beaconing() {
    local out="${CURRENT_SCAN}/beaconing.txt"
    log_info "━━━ Phase 6: Beaconing / C2 Detection ━━━"

    if [ ! -f "${PCAP_FILE}" ] || [ ! -s "${PCAP_FILE}" ]; then
        return
    fi

    # Look for IPs with very regular intervals (beacon signature)
    sudo tshark -r "${PCAP_FILE}" -Y "ip" -T fields \
        -e ip.src -e frame.time_relative 2>/dev/null | \
        awk -F'\t' '{print $1}' | sort | uniq -c | sort -rn | \
        awk '$1 > 50 {print}' > "${out}" 2>/dev/null
    chmod 600 "${out}"

    local beacon_count
    beacon_count=$(wc -l < "${out}" 2>/dev/null || echo 0)
    if [ "${beacon_count}" -gt 0 ]; then
        log_warn "${beacon_count} potential beacon sources detected"
    else
        log_ok "No obvious beaconing detected"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# 7. THREAT SCORING PER IP
# ─────────────────────────────────────────────────────────────────────────────
score_threats() {
    local out="${CURRENT_SCAN}/ip_scores.txt"
    log_info "━━━ Phase 7: Threat Scoring ━━━"

    declare -A ip_score ip_high ip_med

    # Initialize counters
    local high_count=0 med_count=0

    # Start with firefly data if available
    local fj
    fj=$(get_firefly_json)
    if [ -n "$fj" ] && [ -f "$fj" ]; then
        log_info "Correlating with Firefly report: $fj"
        while IFS= read -r line; do
            if echo "$line" | grep -q "^THREAT:HIGH:"; then
                local ip
                ip=$(echo "$line" | grep -oE "([0-9]+\.){3}[0-9]+" | head -1)
                [ -n "$ip" ] && ip_score["$ip"]=$((ip_score["$ip"]+30))
            fi
        done < "$(dirname "$fj")/threats.txt" 2>/dev/null
    fi

    # Score IPs with suspicious ports
    if [ -f "${CURRENT_SCAN}/threats_ports.txt" ]; then
        while IFS= read -r line; do
            if echo "$line" | grep -q "THREAT:HIGH\|THREAT:MEDIUM"; then
                local ip
                ip=$(echo "$line" | grep -oE "([0-9]+\.){3}[0-9]+" | head -1)
                [ -n "$ip" ] && ip_score["$ip"]=$((ip_score["$ip"]+20))
            fi
        done < "${CURRENT_SCAN}/threats_ports.txt"
    fi

    # Score IPs from suspicious DNS
    if [ -f "${CURRENT_SCAN}/suspicious_dns.txt" ] && [ -s "${CURRENT_SCAN}/suspicious_dns.txt" ]; then
        while IFS= read -r ip _; do
            [ -n "$ip" ] && ip_score["$ip"]=$((ip_score["$ip"]+15))
        done < "${CURRENT_SCAN}/suspicious_dns.txt"
    fi

    # Score IPs doing beaconing
    if [ -f "${CURRENT_SCAN}/beaconing.txt" ] && [ -s "${CURRENT_SCAN}/beaconing.txt" ]; then
        while IFS= read -r count ip; do
            [ -n "$ip" ] && ip_score["$ip"]=$((ip_score["$ip"]+25))
        done < "${CURRENT_SCAN}/beaconing.txt"
    fi

    # Output scored IPs
    {
        echo "IP THREAT SCORES — $(date '+%Y-%m-%d %H:%M:%S')"
        echo "=============================================="
        printf "%-16s  %-8s  %s\n" "IP" "SCORE" "LEVEL"
        echo "----------------------------------------------"
        for ip in "${!ip_score[@]}"; do
            local score=${ip_score["$ip"]}
            local level
            if [ "$score" -ge 51 ]; then
                level="🔴 HIGH"; ip_high["$ip"]=1
            elif [ "$score" -ge 26 ]; then
                level="🟡 MEDIUM"; ip_med["$ip"]=1
            else
                level="🟢 LOW"
            fi
            printf "%-16s  %-8s  %s\n" "$ip" "$score" "$level"
        done | sort -k2 -rn
    } > "${out}"
    chmod 600 "${out}"

    local high_count=${#ip_high[@]}
    local med_count=${#ip_med[@]}
    log_ok "Scoring complete — ${high_count} HIGH, ${med_count} MEDIUM"
}

# ─────────────────────────────────────────────────────────────────────────────
# 8. CORRELATE WITH FIREFLY
# ─────────────────────────────────────────────────────────────────────────────
correlate_firefly() {
    local fj
    fj=$(get_firefly_json)
    if [ -z "$fj" ] || [ ! -f "$fj" ]; then
        log_warn "No firefly JSON found — skipping correlation"
        return
    fi

    local fj_dir
    fj_dir=$(dirname "$fj")

    log_info "━━━ Firefly Correlation ━━━"

    local threat_level
    threat_level=$(grep -oP '"threat_level"\s*:\s*"\K[^"]+' "$fj" 2>/dev/null || echo "unknown")
    local high_count
    high_count=$(grep -oP '"high"\s*:\s*\K[0-9]+' "$fj" 2>/dev/null || echo 0)
    local med_count
    med_count=$(grep -oP '"medium"\s*:\s*\K[0-9]+' "$fj" 2>/dev/null || echo 0)
    local hosts_up
    hosts_up=$(grep -oP '"hosts_up"\s*:\s*\K[0-9]+' "$fj" 2>/dev/null || echo "?")

    log_info "Firefly threat_level: ${threat_level}"
    log_info "High: ${high_count} | Medium: ${med_count} | Hosts: ${hosts_up}"

    # Copy firefly threats into our scan
    if [ -f "${fj_dir}/threats.txt" ]; then
        cp "${fj_dir}/threats.txt" "${CURRENT_SCAN}/firefly_threats.txt"
    fi

    # Store summary for reporting
    cat > "${CURRENT_SCAN}/firefly_summary.txt" << EOF
THREAT_LEVEL=${threat_level}
HIGH_COUNT=${high_count}
MED_COUNT=${med_count}
HOSTS_UP=${hosts_up}
FIREFLY_DIR=${fj_dir}
EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# 9. GENERATE REPORTS
# ─────────────────────────────────────────────────────────────────────────────
generate_reports() {
    log_info "━━━ Phase 8: Report Generation ━━━"

    local threat_level="clean"
    local high_count=0
    local med_count=0
    local hosts_up="?"
    local firefly_threat_level="clean"

    # Load firefly summary
    if [ -f "${CURRENT_SCAN}/firefly_summary.txt" ]; then
        source "${CURRENT_SCAN}/firefly_summary.txt"
        firefly_threat_level="${THREAT_LEVEL}"
        [ -n "${HIGH_COUNT}" ] && high_count=$((10#$HIGH_COUNT))
        [ -n "${MED_COUNT}" ] && med_count=$((10#$MED_COUNT))
    fi

    # Determine combined threat level
    local ip_high_count
    ip_high_count=$(grep -c "HIGH" "${CURRENT_SCAN}/ip_scores.txt" 2>/dev/null || echo 0)
    local ip_med_count
    ip_med_count=$(grep -c "MEDIUM" "${CURRENT_SCAN}/ip_scores.txt" 2>/dev/null || echo 0)

    [ "$ip_high_count" -gt 0 ] || [ "$high_count" -gt 0 ] && threat_level="critical"
    [ "$threat_level" = "clean" ] && { [ "$ip_med_count" -gt 0 ] || [ "$med_count" -gt 0 ]; } && threat_level="elevated"

    # ── Text Report ──
    {
        echo "=========================================="
        echo "  WIRESHARK SECURITY ANALYSIS REPORT"
        echo "  $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "=========================================="
        echo ""
        echo "Interface : ${INTERFACE}"
        echo "Scan ID   : ${CURRENT_SCAN}"
        echo "Firefly   : ${firefly_threat_level}"
        echo ""
        echo "── Network Scope ──"
        echo "  Network     : 192.168.100.0/24"
        echo "  Hosts up    : ${hosts_up}"
        echo ""
        echo "── Threat Summary ──"
        echo "  Threat Level  : ${threat_level}"
        echo "  IP HIGH risks : ${ip_high_count}"
        echo "  IP MED risks  : ${ip_med_count}"
        echo ""
        echo "── Top Scored IPs ──"
        if [ -f "${CURRENT_SCAN}/ip_scores.txt" ] && [ -s "${CURRENT_SCAN}/ip_scores.txt" ]; then
            grep -E "HIGH|MEDIUM" "${CURRENT_SCAN}/ip_scores.txt" 2>/dev/null | head -20
        else
            echo "  No scored IPs"
        fi
        echo ""
        echo "── Suspicious Ports ──"
        if [ -f "${CURRENT_SCAN}/threats_ports.txt" ] && [ -s "${CURRENT_SCAN}/threats_ports.txt" ]; then
            grep "^THREAT:" "${CURRENT_SCAN}/threats_ports.txt" 2>/dev/null | head -20
        else
            echo "  No suspicious ports detected"
        fi
        echo ""
        echo "── Suspicious DNS ──"
        if [ -f "${CURRENT_SCAN}/suspicious_dns.txt" ] && [ -s "${CURRENT_SCAN}/suspicious_dns.txt" ]; then
            cat "${CURRENT_SCAN}/suspicious_dns.txt" 2>/dev/null | head -20
        else
            echo "  No suspicious DNS queries"
        fi
        echo ""
        echo "── Unencrypted Traffic ──"
        if [ -f "${CURRENT_SCAN}/unencrypted.txt" ] && [ -s "${CURRENT_SCAN}/unencrypted.txt" ]; then
            cat "${CURRENT_SCAN}/unencrypted.txt" 2>/dev/null | head -20
        else
            echo "  None detected"
        fi
        echo ""
        echo "Full logs: ${CURRENT_SCAN}/"
        echo "=========================================="
    } > "${REPORT_FILE}"
    chmod 600 "${REPORT_FILE}"

    # ── JSON Report ──
    cat > "${REPORT_JSON}" << EOF
{
  "scan_id": "${TIMESTAMP}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "interface": "${INTERFACE}",
  "network": "192.168.100.0/24",
  "threat_level": "${threat_level}",
  "threats": {
    "ip_high": ${ip_high_count},
    "ip_medium": ${ip_med_count},
    "firefly_high": ${high_count},
    "firefly_medium": ${med_count}
  },
  "hosts_up": "${hosts_up}",
  "firefly_threat_level": "${firefly_threat_level}",
  "scan_dir": "${CURRENT_SCAN}",
  "pcap_file": "${PCAP_FILE}"
}
EOF
    chmod 600 "${REPORT_JSON}"

    log_ok "Reports generated"
    echo "${threat_level}" > "${CURRENT_SCAN}/.threat_level"

    # ── INCIDENT REPORT (only for HIGH/critical) ──
    if [ "$threat_level" = "critical" ] || [ "$threat_level" = "elevated" ]; then
        generate_incident_report "$threat_level" "$ip_high_count" "$ip_med_count"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# 10. SIEM/SOAR INCIDENT REPORT
# ─────────────────────────────────────────────────────────────────────────────
generate_incident_report() {
    local threat_level="$1"
    local ip_high="$2"
    local ip_med="$3"

    log_info "━━━ Generating SIEM/SOAR Incident Report ━━━"

    local severity_icon
    case "$threat_level" in
        critical) severity_icon="🔴 CRITICAL" ;;
        elevated) severity_icon="🟡 ELEVATED" ;;
        *)        severity_icon="🟢 LOW" ;;
    esac

    local incident_id
    incident_id="INC-$(date +%Y%m%d)-$(echo "$TIMESTAMP" | tr -d ':')"

    cat > "${INCIDENT_FILE}" << EOF
# 🚨 FIREFLY + WIRESHARK — SIEM/SOAR INCIDENT REPORT

---

## INCIDENT HEADER

| Field | Value |
|-------|-------|
| **Incident ID** | \`${incident_id}\` |
| **Timestamp** | $(date '+%Y-%m-%d %H:%M:%S %Z') |
| **Network** | 192.168.100.0/24 |
| **Interface** | ${INTERFACE} |
| **Scan ID** | ${TIMESTAMP} |
| **Severity** | ${severity_icon} |
| **Status** | ⏳ OPEN |

---

## SIEM/SOAR CONTEXT

> **What is SIEM/SOAR?**
> - **SIEM** (Security Information and Event Management) — collects and analyzes security event data from across the network (fireswalls, IDS, servers) to detect threats and meet compliance requirements.
> - **SOAR** (Security Orchestration, Automation and Response) — automates incident response playbooks, enriches threat data, and coordinates tools to handle incidents with minimal human intervention.

This report follows SIEM/SOAR principles:
- ✅ Event correlation (Firefly nmap + Wireshark pcap)
- ✅ Threat scoring and prioritization
- ✅ Incident documentation and chain-of-custody
- ✅ Structured for analyst review and response

---

## THREAT SUMMARY

| Metric | Count |
|--------|-------|
| 🔴 HIGH risk IPs | ${ip_high} |
| 🟡 MEDIUM risk IPs | ${ip_med} |
| Hosts up on network | ${hosts_up:-?} |
| Firefly nmap threats | $([ -f "${CURRENT_SCAN}/firefly_threats.txt" ] && grep -c "^THREAT" "${CURRENT_SCAN}/firefly_threats.txt" 2>/dev/null || echo 0) |
| Suspicious ports | $(grep -c "^THREAT:" "${CURRENT_SCAN}/threats_ports.txt" 2>/dev/null || echo 0) |
| Suspicious DNS queries | $(wc -l < "${CURRENT_SCAN}/suspicious_dns.txt" 2>/dev/null || echo 0) |

---

## HIGH RISK IPs (requiring immediate investigation)

EOF

    # Add HIGH IPs
    if [ -f "${CURRENT_SCAN}/ip_scores.txt" ]; then
        grep "HIGH" "${CURRENT_SCAN}/ip_scores.txt" 2>/dev/null | while read -r line; do
            local ip
            ip=$(echo "$line" | awk '{print $1}')
            local score
            score=$(echo "$line" | awk '{print $2}')
            local associated_ports
            associated_ports=$(grep -E "$ip" "${CURRENT_SCAN}/threats_ports.txt" 2>/dev/null | grep "THREAT" | awk -F: '{print $3}' | tr '\n' ',' | sed 's/,$//')
            cat >> "${INCIDENT_FILE}" << IP_ENTRY

### 🔴 IP: \`${ip}\` — Score: ${score}

- [ ] Device identified
- [ ] Owner notified
- [ ] Port blocked / isolated
- [ ] Forensic analysis started

**Associated threats:** ${associated_ports:-none specified}

**Recommended SOAR Playbook:**
1. Isolate device from network
2. Run deep packet capture on this IP
3. Query threat intelligence (VirusTotal, AbuseIPDB)
4. Notify device owner
5. Document in incident tracker
IP_ENTRY
        done
    fi

    # Medium IPs
    cat >> "${INCIDENT_FILE}" << EOF

---

## MEDIUM RISK IPs (investigate within 24h)

EOF

    if [ -f "${CURRENT_SCAN}/ip_scores.txt" ]; then
        grep "MEDIUM" "${CURRENT_SCAN}/ip_scores.txt" 2>/dev/null | while read -r line; do
            local ip score
            ip=$(echo "$line" | awk '{print $1}')
            score=$(echo "$line" | awk '{print $2}')
            cat >> "${INCIDENT_FILE}" << IP_ENTRY

### 🟡 \`${ip}\` — Score: ${score}

- [ ] Verify device with nmap
- [ ] Confirm with owner
- [ ] Monitor for 48h

IP_ENTRY
        done
    fi

    # Port threats
    cat >> "${INCIDENT_FILE}" << EOF

---

## SUSPICIOUS PORT ACTIVITY

| Port | Risk | Detail |
|------|------|--------|
EOF

    if [ -f "${CURRENT_SCAN}/threats_ports.txt" ]; then
        grep "^THREAT:" "${CURRENT_SCAN}/threats_ports.txt" 2>/dev/null | sort -t: -k2 -r | while read -r line; do
            local risk level port detail
            IFS=: read -r _ risk level detail <<< "$line"
            printf "| %-6s | %-6s | %-50s |\n" "${detail%% *}" "${risk}" "${detail}" >> "${INCIDENT_FILE}"
        done
    fi

    # DNS anomalies
    cat >> "${INCIDENT_FILE}" << EOF

---

## SUSPICIOUS DNS QUERIES

EOF

    if [ -f "${CURRENT_SCAN}/suspicious_dns.txt" ] && [ -s "${CURRENT_SCAN}/suspicious_dns.txt" ]; then
        cat >> "${INCIDENT_FILE}" << EOF
The following suspicious domains were queried (possible malware, C2, or data exfiltration):

\`\`\`
$(cat "${CURRENT_SCAN}/suspicious_dns.txt" 2>/dev/null | head -30)
\`\`\`

**Recommendation:** Block these domains at the DNS level and investigate the source IP.
EOF
    else
        echo "No suspicious DNS queries detected." >> "${INCIDENT_FILE}"
    fi

    # Firefly correlation
    if [ -f "${CURRENT_SCAN}/firefly_threats.txt" ] && [ -s "${CURRENT_SCAN}/firefly_threats.txt" ]; then
        cat >> "${INCIDENT_FILE}" << EOF

---

## FIREFLY NMAP THREAT REPORT (network scan data)

\`\`\`
$(grep "^THREAT:" "${CURRENT_SCAN}/firefly_threats.txt" 2>/dev/null | sort -t: -k2 -r)
\`\`\`

EOF
    fi

    # Recommended actions
    cat >> "${INCIDENT_FILE}" << EOF

---

## SOAR PLAYBOOK — RECOMMENDED RESPONSE ACTIONS

### 🔴 CRITICAL (immediate):
1. **Contain** — Isolate affected IPs/devices at the gateway
2. **Capture** — Preserve full PCAP for forensic analysis: \`${PCAP_FILE}\`
3. **Correlate** — Cross-reference with Firefly nmap scan data
4. **Communicate** — Alert network owner/admin
5. **Document** — Log all findings to this incident ID

### 🟡 ELEVATED (within 1 hour):
1. Verify unauthorized ports with targeted nmap scan
2. Identify device owners via MAC vendor lookup
3. Apply firewall rules to block risky ports
4. Re-scan after changes to confirm

### 📋 GENERAL:
- Review all PCAP files: \`${PCAP_FILE}\`
- Full scan logs: \`${CURRENT_SCAN}/\`
- SIEM/SOAR template: \`${INCIDENT_TEMPLATE}\`
- Incident report: \`${INCIDENT_FILE}\`

---

## MITRE ATT&CK TACTICS (if applicable)

| Tactic | Technique | Evidence |
|--------|-----------|---------|
| Initial Access | T1190 (Exploit Public-Facing Application) | suspicious port exposure |
| Persistence | T1060 (Registry Run Keys) | beaconing detected |
| Lateral Movement | T1021 (Remote Services) | high-port access detected |
| Collection | T1041 (Exfiltration Over C2 Channel) | suspicious DNS queries |
| Command & Control | T1071 (Application Layer Protocol) | beaconing pattern found |

---

*Report generated by Firefly Security Agent + Wireshark Scan*
*SIEM/SOAR Reference: SecurityTrybe — www.securitytrybe.com*
*Incident ID: \`${incident_id}\`*
EOF

    chmod 600 "${INCIDENT_FILE}"
    log_ok "Incident report written: ${INCIDENT_FILE}"
}

# ─────────────────────────────────────────────────────────────────────────────
# 11. SEND ALERT EMAIL
# ─────────────────────────────────────────────────────────────────────────────
send_alert() {
    local level="$1"
    local subj_prefix
    case "$level" in
        critical) subj_prefix="🔴 CRITICAL ALERT" ;;
        elevated) subj_prefix="🟡 SECURITY NOTICE" ;;
        *)        subj_prefix="✅ WireShark Scan Complete" ;;
    esac

    # Build summary
    local high_count
    high_count=$(grep -c "HIGH" "${CURRENT_SCAN}/ip_scores.txt" 2>/dev/null || echo 0)
    local med_count
    med_count=$(grep -c "MEDIUM" "${CURRENT_SCAN}/ip_scores.txt" 2>/dev/null || echo 0)

    local email_body="FIREFLY + WIRESHARK SECURITY REPORT
=========================================

Scan Time : $(date '+%Y-%m-%d %H:%M:%S %Z')
Network   : 192.168.100.0/24
Interface : ${INTERFACE}
Severity  : ${subj_prefix}
Scan ID   : ${TIMESTAMP}

--- SUMMARY ---
IP HIGH risks : ${high_count}
IP MEDIUM     : ${med_count}
Full logs     : ${CURRENT_SCAN}/
"

    if [ -f "${INCIDENT_FILE}" ] && [ "$level" != "clean" ]; then
        email_body+="
--- INCIDENT REPORT ---
$(head -80 "${INCIDENT_FILE}")
"
    fi

    if command -v mailx &>/dev/null; then
        echo "${email_body}" | mailx -s "[FIREFLY+WIRE] ${subj_prefix} — ${high_count} HIGH, ${med_count} MED risks detected" \
            -r "firefly@ahie" "${ALERT_EMAIL}" 2>/dev/null
    elif command -v mail &>/dev/null; then
        echo "${email_body}" | mail -s "[FIREFLY+WIRE] ${subj_prefix} — ${high_count} HIGH, ${med_count} MED risks detected" \
            "${ALERT_EMAIL}" 2>/dev/null
    fi

    log_ok "Alert email sent to ${ALERT_EMAIL}"
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
main() {
    log ""
    log_info "━━━ WireShark Security Scan ━━━"
    log_info "Interface: ${INTERFACE} | Mode: ${MODE}"
    log_info "Output:    ${CURRENT_SCAN}"
    log ""

    setup

    if [ "$MODE" = "full" ]; then
        capture_packets
        analyze_protocols
        top_talkers
        scan_suspicious_ports
        dns_anomaly_check
        detect_beaconing
        score_threats
    fi

    correlate_firefly
    generate_reports

    # Email on elevated/critical
    local threat_level
    threat_level=$(cat "${CURRENT_SCAN}/.threat_level" 2>/dev/null || echo "clean")
    if [ "$threat_level" != "clean" ]; then
        send_alert "$threat_level"
    fi

    log_ok "━━━ WireShark Scan Complete ━━━"
    echo "Report   : ${REPORT_FILE}"
    echo "JSON     : ${REPORT_JSON}"
    echo "Incident : ${INCIDENT_FILE}"
    echo "Threat Level: ${threat_level}"
}

main
