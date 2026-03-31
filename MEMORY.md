# MEMORY.md — Oracle's Long-Term Memory

> Last updated: 2026-03-30 3:37 PM GMT+3

---

## 🧠 Identity

- **I am Oracle** — Gibson's second brain, running on Termux via OpenClaw
- Gibson is my human — he trusts me with his digital life, decisions, and communications
- I remember everything that matters in these files

---

## 👤 About Gibson

- **Name:** Gibson (also "Gibsons", "Gib")
- **Timezone:** Africa/Nairobi (GMT+3)
- **Setup:** Termux (Android) + OpenClaw as smart agent
- **Host:** ahie (192.168.100.182) — home server running docker stacks

### What Gibson is Building
- **MoltChain** — L3 blockchain on Base for the AI agent economy, aiming to be #2 chain after Bitcoin
- Moltbook presence: **AhieJuma** (119 karma), growing ecosystem
- Docker stacks: bridge_api, crypto stacks, dao_wallet, gibsons_dash, ZeroTier tunnels
- Various crypto bots and DeFi tools

### How to Help Gibson Best
- Be direct and practical — no corporate fluff
- Surface important things proactively
- Help him make decisions, don't just list options
- Keep his private things private

---

## Network Infrastructure

### Subnet
- `192.168.100.0/24` — primary LAN
- This machine: `192.168.100.182` (hostname: `ahie`)

### ADB Connection to LG V20
- **Device:** LG V20 (Android 7.0, kernel 4.19.191, armv7l)
- **Serial:** 20429563B4043064
- **Connection:** USB 3-6 (adb daemon detected, USB debugging enabled)
- **Status:** ✅ Connected — full dumpsys access available
- **Previously:** Lost USB debug on 2026-03-29, reconnected 2026-03-30
- **SIM 1:** Secondary slot — OUT_OF_SERVICE, radio powered off
- **SIM 2:** Primary Safaricom (MCC 639/MNC 02) — IN_SERVICE, HSPA, level 4/4
- **Cell towers:** LAC 2598, CID 72514437/72518261 — stable registration since 15:12
- **Battery:** 37%, USB charging, 34°C, healthy, 500mA slow charge
- **Screen:** Awake, unlocked, Launcher active

### Known Devices on LAN (scan 2026-03-30 evening)

| IP | Device | MAC Vendor | Key Services | Status |
|----|--------|-----------|-------------|--------|
| 192.168.100.1 | Huawei Router (gateway) | Huawei Technologies | telnet 23 ⚠️ OPEN, DNS 53, HTTP 80 | ⚠️ telnet accessible — security risk |
| 192.168.100.4 | LG Smart TV | 60:8D:26:B1:AF:4F | HTTP :3000 (LG smart TV service) | ✅ |
| 192.168.100.21 | TP-Link device | TP-Link Technologies | all ports filtered | 🔒 firewalled |
| 192.168.100.50 | Unknown | — | ports 49152, 62078 (tcpwrapped) | ⚠️ unknown — possibly ADB-related Android device |
| 192.168.100.116 | D-Link device | D-Link International | all ports filtered | 🔒 firewalled |
| 192.168.100.122 | Server (Bitsoko) | TP-Link Technologies | SSH 22, HTTP 80, Samba 139/445, MySQL 3306, Abyss 9999 | ⚠️ MySQL on LAN |
| 192.168.100.182 | This machine (ahie) | — | SSH 22, SMTP 25, DNS 53, HTTP 80, Docker Swarm, ZeroTier, OpenClaw; port 3000 filtered | ✅ |
| 192.168.100.224 | Oraimo device | — | all ports closed | ⚠️ |
| 192.168.100.251 | Unknown | — | not responding | ⚠️ missing since 2026-03-21 |
| 192.168.100.138 | Unknown | — | not seen in evening scan | ⚠️ may be intermittent |

### Oracle Security Operations — ⚔️ ACTIVE (as of 2026-03-30)
Oracle now autonomously manages all security logs and network scans for Gibson's infrastructure.

**Oracle's Security Mandate:**
- Monitor and analyze network traffic anomalies via TShark/Wireshark
- Run periodic LAN scans (nmap) and report new devices/threats
- Audit Docker container health and exposed services
- Review cron job integrity (remove malicious jobs)
- Alert on: new devices, port changes, unusual traffic patterns, service exposures
- Store security events in `memory/security-YYYY-MM-DD.md`

**Security Tool Stack:**
- `tshark` (Wireshark CLI) at `/usr/bin/tshark` — packet capture and analysis
- `nmap` — LAN device discovery and port scanning
- `iptables` / `nft` — firewall review
- `auditd` — system call monitoring (if installed)
- Docker daemon logs — container-level anomalies
- `dumpsys telephony.registry` — radio/SIM anomalies on Android

**Security Log Location:** `memory/security-2026-03-30.md` (ongoing)
### Previously Seen (last seen before 2026-03-31)
| IP | Device | Last Seen | Notes |
|----|--------|-----------|-------|
| 192.168.100.251 | Unknown | 2026-03-21 | Not responding since 2026-03-21 |
| 192.168.100.138 | Unknown | 2026-03-30 morning | Not seen in evening scan — intermittent availability |
| 192.168.100.4 (LG TV) | 2026-03-30 | Had HTTP:3000, now all filtered |

### Previously Seen (last seen before 2026-03-30)
| IP | Device | Last Seen | Notes |
|----|--------|-----------|-------|
| 192.168.100.251 | Unknown | 2026-03-21 | Not responding since 2026-03-21 |
| 192.168.100.138 | Unknown | 2026-03-30 morning | Not seen in evening scan — intermittent availability |

### Security Concerns (as of 2026-03-27)
1. ⚠️ Router (.1): telnet port 23 is **OPEN** — unencrypted protocol, actively accessible. HIGH priority to disable.
2. ⚠️ .122: MySQL 5.7.44 exposed on LAN with autocommit + mysql_native_password. SMB signing not required.
3. ⚠️ .122: Port 9999 (abyss) open — HTTP service on unknown port, not recognized by nmap.
4. .182: Postfix SMTP (:25) listening on all interfaces — verify intentionality.
5. 🆕 .50: Unknown device with ports 49152 & 62078 open (tcpwrapped). Port 62078 is associated with Android Debug Bridge (ADB) over TCP — possible Android device oradb-related service. MAC not in OUI database. Identity unknown — investigate.

### Security Concerns (as of 2026-03-21)
1. Router (.1): telnet port 23 open — unencrypted protocol, known exploits. Recommend disabling.
2. .122: MySQL 5.7.44 exposed on LAN with autocommit + mysql_native_password. SMB signing not required.
3. .182: Postfix SMTP (:25) listening on all interfaces — verify intentionality.

### This Machine Services (192.168.100.182)
- **:22** SSH (OpenSSH 8.9p1) — 0.0.0.0
- **:25** Postfix SMTP — all interfaces
- **:53** BIND 9.18.39 — all interfaces + IPv6
- **:80** HTTP — Duka DAO (Node.js/Express) on port 80 (previously was HAProxy)
- Docker Swarm — ports 2377, 7946
- **Local only:** Ollama :11434, netdata :19999, Tor :9050, OpenClaw Gateway :18789-18792
- ZeroTier :9993, Cloudflare WARP, WireGuard-style tunnel (10.8.0.1)

### Docker Containers Running (updated 2026-03-30 15:49 EAT)
**Critical issues:**
- `crypto_nginx` — 🔴 **RESTART LOOP** (~44s restart cycle) — restart count 1, affecting crypto stack
- `crypto_phone`, `crypto_dns`, `crypto_mpesa` — ⚠️ **UNHEALTHY** (up 21h, unhealthy flag)
- `crypto-register-api`, `trading-api`, `bridge-api-dev` — 💀 **Exited (255)** since 7 days

**Healthy containers:** bridge_api, bridge_heartbeat, bridge_tracker, bridge_db, crypto_redis, portainer, stack-duka-dao-app-1, trusting_beaver, gibsons_dash, dao_wallet, zerotier, crypto-register-frontend, crypto_loki (starting up)

**Host load:** MEDIUM — load avg 13.83 (i3-4130, 4 threads), RAM 9.2/12GiB used, swap 100% full. **Root cause: Firefox browser (~39% CPU, ~17% RAM across ~10 processes + isolated tabs)** — not containers. OpenClaw gateway at 2.3% CPU is normal. Cloudflare WARP, netdata, and gnome-shell are contributing but within expected range.

---

## MoltChain Ecosystem

### Key Agents on Moltbook
| Agent | Karma | Priority | Status |
|-------|-------|----------|--------|
| tudou_web3 | 2,721 | 🔥🔥🔥 | MASSIVE reach — PRIMARY URGENT |
| PayRam | 849 | 🔥🔥 | Crypto/DeFi alignment |
| Molty | 246 | ⭐⭐⭐ | PRIMARY outreach target |
| molthunty | 141 | ⭐⭐⭐ | Partnership — Molthunt listing |
| MoltChat_AI | 54 | ⭐⭐ | Social layer partnership |
| MoltChain | 1 | Core | Our L3 chain agent |
| MoltChainHQ | 0 | Core | Official account |
| clawchain | 2 | 🔗 | Ally — on-chain coordination |
| AhieJuma | 119 | Core | Gibson's agent identity |

### 🔥 TRENDING — "Settlement Layer Problem" (2026-03-24)
**MoltChain's moment is NOW.** These posts are trending RIGHT NOW on Moltbook:
- "The settlement layer problem for AI agent economies" — **10 upvotes** 🔥🔥🔥
- "The agent economy has a settlement layer problem. Here is what 500+ transactions..." — 3 upvotes
- "Hot Post (Last 12h): The agent economy has a settlement problem" — 6 upvotes

**This is EXACTLY what MoltChain solves.** Gibson just needs dashboard access to join the conversation.

### MoltChain Status
- Read operations: ✅ Working
- Write operations: ❌ Blocked — dashboard setup needed at https://www.moltbook.com/help/connect-account
- Discord config: ❌ Not configured

### Outreach Templates (ready to send when dashboard is set up)
See TOOLS.md for full templates.

---

## ⚠️ Security Incident — 2026-03-20 23:57
Malicious cron job "Oracle" removed. Was attempting ADB extraction of call logs/SMS/voice recordings from Android device. No data extracted (script was erroring before execution; no exports directory existed). Job ID: `f085e085-6cff-4fcc-8a53-59d4c85fa54f`. 

**Also audit these cron jobs (consecutive errors, may contain suspicious content):**
- "Microservices" (ID: 2fb27623-ddfa-4d68-a7c4-46ba839517a3) — 31 consecutive errors
- "MOLTCHAIN" (ID: 52530b65-a2c7-4fd5-a425-48947e1d4c38) — currently ok but needs review

---

## Skills & Tools

### nmap-scan
- Location: `/root/.openclaw/workspace/skills/nmap-scan/`
- Trigger: "scan network", "nmap scan", "find devices", "port scan"
- Command: `nmap -sn -PR 192.168.100.0/24`

### Oracle Security Operations
- **Security ledger:** `memory/security-YYYY-MM-DD.md` — daily security events
- **Oracle's mandate:** autonomous network forensics, LAN scans, Docker health, cron auditing
- **Tool stack:** tshark (Wireshark CLI), nmap, iptables, docker logs, dumpsys
- **TShark interfaces:** tun0, zt6ovzovul, CloudflareWARP, enp0s25, docker0, br-*, any

---

## Cron Jobs Active

| Name | ID | Schedule | Status | Notes |
|------|----|---------|--------|-------|
| personal_assistant | ed7dd4d8-3762-430f-9fb9-e8f4d30faf19 | 30 min | ⚠️ 10 errors | Typo in name + no channel; Gibson needs Telegram/WhatsApp |
| workspace-manager | b544d2e1-20b8-4b04-9297-a8cef4f06f64 | 5 min | ⚠️ 4 errors | No channel configured; same fix as above |
| workspace-backup | 9eb3df4b-9bd6-483e-8ad6-be361fb6a1fb | 3 AM | ⏳ next 3AM | Daily backup script |
| Daily Network Scan | f5f01037-6942-4a6e-a562-8d9740a473cc | 6 AM EAT | ⚠️ error | OpenRouter rate limit / billing issue |
| MOLTCHAIN | 52530b65-a2c7-4fd5-a425-48947e1d4c38 | 30 min | ✅ ok | Growing ecosystem |
| Microservices | 2fb27623-ddfa-4d68-a7c4-46ba839517a3 | — | ✅ REMOVED | Was: 50+ consecutive errors, removed 2026-03-22 |

---

## Key Files

### Portainer — Docker Management UI
- **URL:** https://192.168.100.182:9443/#!/auth
- **Credentials:** admin / (check daily notes — temp password set on 2026-03-29)
- **Port:** :9443 (HTTPS, self-signed cert)
- **Data volume:** /var/lib/docker/volumes/portainer_data/_data/portainer.db
- **Admin user hash location:** byte offsets 14234, 18330, 22426 in portainer.db
- **Reset method:** Patch bcrypt hash directly in SQLite DB (portainer was stopped, hash replaced, restarted)
- **Note:** AuthenticationMethod=1 (internal), RequiredPasswordLength=12

- `memory/moltchain_activity.md` — full MoltChain engagement log
- `MOLTCHAIN_DISCORD_SETUP.md` — Discord status and ecosystem map
- `memory/heartbeat-state.json` — periodic check timestamps

---

## Oracle's Second Brain — Obsidian Blueprint

**Created:** 2026-03-22
**Location:** `/root/.openclaw/workspace/obsidian/`
**Last Expanded:** 2026-03-30 3:37 PM EAT

### Complete Mind Map Structure (7 Dimensions, 22 Files)

```
obsidian/
├── 00-GIBSON-SECOND-BRAIN.md     ← ROOT INDEX (master navigation)
├── 01-LIFE/
│   ├── Life-Overview.md          ← Health, goals, habits, vision
│   └── Strategic-Roadmap.md      ← Long-term goals, 2026 plan
├── 02-PROJECTS/
│   ├── MoltChain/
│   │   ├── MoltChain-Home.md     ← Ecosystem overview, strategy
│   │   ├── MoltChain-Status.md   ← Current karma, metrics
│   │   └── MoltChain-Targets.md  ← Outreach targets + templates
│   └── Docker/
│       └── Docker-Overview.md    ← Container status, health
├── 03-INFRASTRUCTURE/
│   ├── Network/
│   │   └── Network-Status.md     ← LAN map, all devices, services
│   ├── Security/
│   │   └── Security-Audit.md     ← Full security audit + fixes
│   └── Android/
│       └── Android-ADB-Setup.md  ← USB debugging, ADB connect
├── 04-CONTACTS/
│   └── Contact-Index.md          ← Key relationships, priorities
├── 05-DECISIONS/
│   └── Decision-Log.md           ← Trade-off analysis, framework
├── 06-KNOWLEDGE/
│   └── Tools-Reference.md        ← Oracle capabilities + limits
└── 07-LOGS/
    ├── 2026-03-22-AM.md
    ├── 2026-03-22-PM.md
    ├── 2026-03-23-AM.md
    ├── 2026-03-24-AM.md
    ├── 2026-03-30-AM.md
    └── 2026-03-30-PM.md
```

### Mind Map Navigation

**ROOT:** `00-GIBSON-SECOND-BRAIN.md` — Start here
**LIFE:** Health, goals, habits, financial, relationships
**PROJECTS:** MoltChain (L3 blockchain), Docker stacks
**INFRASTRUCTURE:** Network, Security, Android/ADB
**CONTACTS:** MoltChain ecosystem, business contacts
**DECISIONS:** Trade-off framework, pending decisions
**KNOWLEDGE:** Oracle capabilities and limitations
**LOGS:** Session history, metrics, security logs

---

## Current Gaps & Owner Action Items (as of 2026-03-27)

| Priority | Item | Days Pending | How to Fix |
|----------|------|--------------|------------|
| 🔴 | Moltbook dashboard | 8+ days | https://www.moltbook.com/help/connect-account |
| 🔴 | Google Storage 4% | 8+ days | myaccount.google.com → Storage |
| 🔴 | Google Security alerts | 8+ days | myaccount.google.com/security |
| 🔴 | ADB/Android | UNADDRESSED | Install OpenClaw app + pair |
| 🟡 | EcoBank inactive | UNADDRESSED | Paybill 700201, fund acct |
| 🟡 | RUFAS ATENG uncalled | UNADDRESSED | Call 0723288566 |
| 🟡 | Messaging channel | UNADDRESSED | Telegram or WhatsApp setup |

---

_Remember: I'm Gibson's second brain. What matters to him matters to me. Keep these files accurate and up to date._

---

## 🏗️ Workspace Manager (Active as of 2026-03-22)

### What
Oracle's autonomous docker workspace management agent. Enforces 30% resource ceiling, monitors 20 containers, intervenes automatically when thresholds are crossed.

### Policy
- **30% ceiling** on docker memory (3.6 GiB on 12 GiB system)
- OpenClaw maintains 1 GiB minimum reserve always
- Intervention ladder: Tier 4 → Tier 3 → Tier 2 → Emergency
- Never stop Tier 1: openclaw, zerotier, portainer

### Components
| File | Purpose |
|------|---------|
| `WORKSPACE_RULES.md` | Canonical policy — read before any resource action |
| `workspace-manager/AGENT.md` | Agent instructions and workflows |
| `workspace-manager/WORKSPACE_MANAGER.md` | Architecture & design docs |
| `workspace-manager/logs/interventions.md` | All throttle/stop decisions |
| `workspace-manager/logs/metrics.md` | Periodic resource snapshots |
| `workspace-manager/logs/decisions.md` | Full decision reasoning |
| `workspace-manager/scripts/resource_check.sh` | Resource polling script |
| `workspace-manager/scripts/emergency_compact.sh` | Auto-compaction script |

### Cron Jobs
- `workspace-manager-resource-check` — runs every 5 min, isolated agentTurn session

### Current Status (2026-03-22)
- Docker usage: **3%** of ceiling (well within limits)
- System memory pressure: **HIGH** (system at 77%, but docker is light)
- Swap: **FULL** (2 GiB used) — kernel pressure, not container issue
- All 20 containers running normally

### Key Insight
Docker containers are NOT the memory problem. System at 9.3/12 GiB used is mostly kernel + host processes. Docker is only ~380 MiB. The 30% ceiling policy is a safeguard against container growth, not current usage.

---
ard against container growth, not current usage.

---
