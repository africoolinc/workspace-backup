---
name: nmap-scan
description: Network scanning and local service discovery using nmap. Use when asked to scan the local network, enumerate devices, check open ports, identify running services, or perform network reconnaissance. Triggers on "scan network", "nmap scan", "find devices", "port scan", "local network status", "connected devices", "network discovery", or any request involving network reconnaissance or service enumeration.
---

# nmap-scan Skill

Network reconnaissance and service discovery using `nmap`.

## Common Workflows

### 1. Local Network Device Discovery

Discover all devices on the local subnet:

```bash
nmap -sn 192.168.1.0/24 -oG - | grep "Status: Up"
```

Or use ARP sweep:
```bash
nmap -sn -PR 192.168.1.0/24
```

### 2. Quick Port Scan (Top Ports)

Fast scan of commonly open ports on a target:
```bash
nmap -F -T4 <target>
```

### 3. Full Port Scan

All 65535 ports, service/version detection, and OS detection:
```bash
nmap -p- -A -T4 <target>
```

### 4. Service Version Detection

Identify running services and versions:
```bash
nmap -sV --version-intensity 5 <target>
```

### 5. Stealth SYN Scan

Privileged port scan (requires root):
```bash
sudo nmap -sS <target>
```

### 6. Common Scan Patterns

| Goal | Command |
|------|---------|
| Live hosts only | `nmap -sn <subnet>` |
| Top 20 ports | `nmap --top-ports 20 <target>` |
| UDP scan | `nmap -sU <target>` |
| Aggressive (OS+services+scripts) | `nmap -A <target>` |
| Save to file | `nmap -oA scan_results <target>` |

## Finding the Local Subnet

Before scanning, identify the local network range:
```bash
ip addr show | grep "inet "       # Linux
ipconfig | grep "IPv4"             # Windows
ifconfig | grep "inet "            # macOS
```

Typical home/small office ranges: `192.168.1.0/24`, `10.0.0.0/24`, `192.168.0.0/24`.

## Output Formats

- `-oN file.nmap` — Normal output
- `-oX file.xml` — XML output
- `-oG file.grep` — Grepable output
- `-oA file` — All formats at once

## Privilege Notes

- `-sS` (SYN scan) requires root/elevated privileges
- Non-privileged: use `-sT` (TCP connect scan)
- Run `sudo` if available and appropriate

## Example: Full Local Network Scan

```bash
# Discover live hosts
nmap -sn 192.168.1.0/24 -oG lan-discovery.gnmap

# Quick port scan on each found host
nmap -F -T4 192.168.1.0/24

# Service/version detection on specific host
nmap -sV 192.168.1.1
```

## Script Execution (NSE)

Run default safe scripts:
```bash
nmap --script default,safe <target>
```

## Important Considerations

- **Authorization**: Only scan networks and hosts you own or have explicit permission to scan.
- **Rate limiting**: Use `-T1` or `-T2` on sensitive networks to avoid triggering IDS/IPS.
- **Firewall evasion**: Use `-Pn` to skip ping (treat host as alive) if hosts block ICMP.
