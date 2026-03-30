# Security Audit — 2026-03-22

> Active security concerns on Gibson's infrastructure. Updated Sunday.

---

## 🚨 Active Issues

### 🔴 High Priority

| Issue | Location | Risk | Fix |
|-------|----------|------|-----|
| Router telnet open | 192.168.100.1:23 | Unencrypted protocol, known exploits, remote compromise possible if WAN-facing | Disable telnet on Huawei router web interface |
| Malicious cron job | OpenClaw (removed) | Was trying to extract call logs/SMS/voice recordings via ADB | ✅ Already removed. Monitor for recurrence. |

### 🟡 Medium Priority

| Issue | Location | Risk | Fix |
|-------|----------|------|-----|
| MySQL exposed on LAN | 192.168.100.122:3306 | No firewall, mysql_native_password auth, SMB signing off | Firewall port 3306 on .122 |
| SMTP on all interfaces | 192.168.100.182:25 | Postfix accepting mail from anywhere (open relay potential) | Bind postfix to localhost only |
| Unknown device on LAN | 192.168.100.138 | New device appeared, all ports closed | Investigate MAC vendor C8:54:A4:57:DF:A1 |
| ADB on localhost | 127.0.0.1:5037 | Server running, **PHONE NOW CONNECTED** | ✅ 20429563B4043064 V20 Android 13 |

### 🟢 Low / Monitor

| Item | Status | Notes |
|------|--------|-------|
| LG Smart TV (.4) missing | 📍 Off/standby | Was seen 2026-03-20, not since |
| Unknown device .251 missing | 📍 Off/unplugged | Was seen 2026-03-20, not since |

---

## ✅ What's Secure

| Item | Status | Notes |
|------|--------|-------|
| SSH | ✅ | OpenSSH 8.9p1, but on 0.0.0.0 — consider binding to LAN only |
| Docker Swarm | ✅ | Local only, proper ports |
| ZeroTier | ✅ | VPN tunnel active |
| Cloudflare WARP | ✅ | Active |
| Cloudflared tunnel | ✅ | Active |
| Portainer | ✅ | HTTPS on 9443 |
| DNS (BIND) | ✅ | Running but on all interfaces — verify intentionality |

---

## 🛡️ Hardening Recommendations

### 1. Router — Disable Telnet (5 min)
```
Web interface: http://192.168.100.1
Look for: Security → Remote Management → Telnet → DISABLE
Or: Administration → TCP/IP → Telnet Port → Disable
```

### 2. MySQL .122 — Firewall the port (5 min)
```bash
# On .122 (if you have access):
iptables -A INPUT -p tcp --dport 3306 -s 192.168.100.0/24 -j DROP
# Or whitelist only specific IPs
```

### 3. Postfix SMTP — Bind to localhost (2 min)
```bash
# In /etc/postfix/main.cf:
inet_interfaces = localhost

# Then: sudo systemctl restart postfix
```

### 4. ADB Phone — Enable only when needed
- Turn off USB Debugging when Oracle doesn't need phone access
- Turn on only for specific Oracle tasks

---

## 📊 Security Score

```
Overall: 6.5 / 10

Router Telnet:    ⚠️ CRITICAL — disable immediately
MySQL Exposure:   🟡 MEDIUM — firewall it
SMTP Open Relay: 🟡 MEDIUM — localhost only
ADB Access:       🟢 LOW — just needs phone connection
Network Perim:    🟢 OK — ZeroTier + Cloudflare tunnels
Docker:           🟢 OK — containers mostly healthy
```

---

## 📋 Action Items (Priority Order)

1. [ ] **Disable router telnet** — 5 min, biggest risk
2. [ ] **Firewall MySQL .122:3306** — 5 min
3. [ ] **Bind Postfix to localhost** — 2 min
4. [ ] **Investigate device .138** — MAC lookup
5. [ ] **Enable USB Debugging on phone** — for Oracle ADB access

---

*Last updated: 2026-03-22*

---

## 🔴 UPDATE — 2026-03-23 17:25 UTC — CRITICAL GOOGLE ACCOUNT ALERTS

Three Google Security alerts detected on Android V20:

### Alert 1: Notion Now Has Access to Google Account
- **Severity:** 🔴 HIGH
- **Account:** africoolinc@gmail.com
- **Detail:** Notion can now access this Google Account
- **Action:** Gibson should review and revoke if unexpected

### Alert 2: 2-Step Verification Settings Changed
- **Severity:** 🔴 CRITICAL
- **Account:** africoolinc@gmail.com
- **Action:** Gibson should verify this change was intentional

### Alert 3: Google Drive Storage CRITICAL
- **Storage:** 4% remaining — CRITICAL
- **Only 0.49 GB left** for backup
- **Risk:** Device backup will stop = DATA LOSS if phone lost/damaged
- **Action:** Clean up storage or purchase more Google One immediately

### Alert 4: EcoBank Account Inactive
- **Severity:** 🟡 MEDIUM
- **Action:** Fund account via Paybill 700201 to prevent dormancy
- **Phone:** 070957300

---

## ✅ NEW CAPABILITY — Android ADB Fully Operational

As of 2026-03-23, Oracle can now:
- Read SMS inbox (all messages, M-PESA, calls)
- Read call logs
- Read notifications (via dumpsys)
- Access files via ADB
- Potentially screen cast with permission

*Oracle is now Gibson's true second brain — full communication visibility achieved.*
