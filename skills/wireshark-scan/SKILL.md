# wireshark-scan — Wireshark / TShark Network Deep Packet Analysis Skill

## Purpose
Use `tshark` (Wireshark CLI) to perform deep packet inspection on the LAN, targeting:
- Suspicious/unexpected traffic from/to malicious or unknown IPs
- Risky ports not authorized by the admin
- Anomalous protocols and beaconing behavior
- Correlate findings with Firefly security scan results

## Prerequisites
- `tshark` installed (`apt-get install tshark`)
- Run as root (required for raw socket capture)
- LAN interface auto-detected (default: upstream gateway interface)

## Usage Triggers
- "run wireshark scan", "tshark scan", "deep packet analysis", "packet capture"
- "analyze suspicious IP", "check port 23", "scan for malicious traffic"
- After Firefly alerts (critical/elevated) — automated via firefly-cron
- "incident report", "forensic analysis"

## Files
- `wireshark-scan.sh` — main script (standalone or cron-called)
- `incident_response.jpeg` — SIEM/SOAR reference card (embedded in reports)

## Key Features
1. **Passive packet capture** on LAN interface (5-min windows)
2. **Protocol distribution** — HTTP, HTTPS, DNS, SMTP, SSH, etc.
3. **Top talkers** — IPs with highest packet/byte counts
4. **Suspicious port detection** — flags non-authorized ports (telnet:23, ftp:21, mysql:3306, etc.)
5. **Unencrypted protocol alerts** — flags telnet, FTP, HTTP, unencrypted SMTP
6. **DNS query analysis** — unusual or suspicious domain lookups
7. **Anomaly scoring** — scores IPs/traffic as low/medium/high risk
8. **Firefly correlation** — imports threat IPs from firefly.sh JSON report
9. **Incident report** — SIEM/SOAR-formatted markdown report emailed on HIGH alerts
10. **PCAP export** — saves raw captures for forensic follow-up

## Architecture
```
wireshark-scan.sh
  ├── capture_packets()      — tshark live capture (5 min default)
  ├── analyze_protocols()     — protocol distribution
  ├── top_talkers()           — highest-volume IPs
  ├── scan_suspicious_ports() — risky port detection
  ├── check_unencrypted()     — telnet/ftp/http detection
  ├── dns_anomaly_check()     — suspicious domain queries
  ├── score_threats()         — risk scoring per IP
  ├── correlate_firefly()     — merge with firefly.sh JSON
  ├── generate_report()       — text + JSON + incident markdown
  └── send_alert()            — email if HIGH threats found
```

## Cron Integration
Runs automatically after Firefly when threat_level ≥ elevated:
```
0 7 * * * root /usr/local/bin/firefly-cron.sh >> /var/log/firefly-cron.log 2>&1
```
Firefly-cron calls wireshark-scan.sh when appropriate.

## Risk Scoring
| Score | Level | Criteria |
|-------|-------|----------|
| 0-25 | 🟢 LOW | Known services, normal traffic |
| 26-50 | 🟡 MEDIUM | Unexpected ports, high volume from unknown |
| 51+ | 🔴 HIGH | Malicious IP match, suspicious beacon, unencrypted creds |

## Admin-Authorized Ports (baseline)
22, 53, 80, 443, 587, 993, 995, 3000, 3100, 5000, 8000, 8080, 8443, 10000, 18789

Any port NOT in this list is flagged as `UNEXPECTED` and scored accordingly.
