# MEMORY.md — Oracle's Long-Term Memory

> Last updated: 2026-04-14 5:50 PM GMT+3

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

## 💰 FINANCIAL STATUS — CRITICAL (2026-04-14 Evening)

### M-PESA — ~Ksh 70 Balance 🔴
**Pattern: STILL paycheck to paycheck.**
- Apr 12: Stanley Wahomegicheri (Equity) -Ksh 100 → ~Ksh 70.27
- Apr 11: Esperance Uwineza -Ksh 50 → Ksh 170.27
- Apr 10: Joyce Midrecha -Ksh 70, Airtime +Ksh 20 → Ksh 320.27
- Apr 9: KPLC -Ksh 4,000 → Ksh 8,862.29
- **No buffer maintained** — every influx immediately consumed
- **Ksh 5,000 minimum rule VIOLATED** — dropped from 8,862 to ~70 in 3 days

### Financial Rule (CRITICAL):
> **Hold Ksh 5,000 minimum in M-PESA. Spend above that threshold only.**

### Other Accounts
| Account | Balance | Status |
|---------|---------|--------|
| ZIIDI | Ksh 40.31 | 🟡 Low |
| Ecobank | Inactive | 🔴 Paybill 700201 |
| ODIBETS | Activated | 🟢 |

### Key Financial Contacts
| Contact | Issue |
|---------|-------|
| erick omondi | Frequent recipient — Ksh 200 Mar 30 |
| NCBA | Loan payments |
| RUFAS ATENG (0723288566) | 10+ missed calls, likely Ksh 530 repayment — CALL TODAY |

---

## 📱 Android Device (LG V20) — Updated 2026-04-14

### Device Info
- **Model:** LG V20 (SN: 20429563B4043064)
- **Status:** ❌ ADB DISCONNECTED — 5+ days unreachable
- **Last sync:** 2026-04-09 (5 days ago)
- **Battery:** Unknown (was 28%, Charging on Apr 9)
- **Cell:** LAC 2598, CID 72514441, Safaricom (Apr 9 state)
- **Storage:** 7.6G/26G used (30%) ✅ | RAM: 1032MB / 1939MB available
- **Android ID:** 2d528612edf23efc

### Oracle Android Sensor System — DISCONNECTED
- **oracle_sensor_local.sh:** Running on /sdcard/Download/ — no termux, 100% offline
  - Collects: battery, cell tower (LAC/CID), WiFi, SIM, device info → JSON
  - Stores: /sdcard/Download/.oracle/data/scan_lgv20_*.json (last 100)
  - Triggers: every 2h OR on cell tower change
- **oracle_sync.sh:** Host-side, running every 30min via cron
  - **NOT SYNCING** — ADB disconnected since Apr 9
- **Cell tower:** LAC 2598 ↔ 2430 oscillating (Safaricom) — Apr 9 state

### ⚠️ Known Issues
- **ADB DISCONNECTED** — 5+ days, LG V20 unreachable via USB

---

## Network Infrastructure

### Subnet
- `192.168.100.0/24` — primary LAN
- This machine: `192.168.100.182` (hostname: `ahie`)

### Known Devices on LAN (scan 2026-04-14 PM)

| IP | Device | MAC Vendor | Key Services | Status |
|----|--------|-----------|-------------|--------|
| 192.168.100.1 | Huawei Router (gateway) | Huawei Technologies | telnet 23 ⚠️ OPEN, DNS 53, HTTP/HTTPS 80/443 | ⚠️ telnet accessible — security risk |
| 192.168.100.4 | LG Smart TV | Unknown | all ports filtered 🔒 (was open on 3000 Apr 9, now silent) | 🔒 possibly sleeping |
| 192.168.100.105 | TP-Link device | F4:F2:6D:CE:85:D0 | all ports filtered | 🔒 |
| 192.168.100.116 | D-Link device | D-Link | all ports filtered | 🔒 |
| 192.168.100.122 | Bitsoko Server | CC:32:E5:0A:7D:7B | SSH 22, HTTP 80, Samba 139/445, MySQL 3306, Abyss 9999 | ⚠️ MySQL on LAN |
| 192.168.100.182 | This machine (ahie) | — | SSH 22, SMTP 25, DNS 53, HTTP 80, Node.js 8080, Docker Swarm, ZeroTier, OpenClaw | ✅ |
| 192.168.100.224 | Oraimo device (RETURNED) | 5C:E8:B7:68:7F:38 | all ports closed | ✅ RETURNED |

### Previously Seen
| IP | Device | Last Seen | Notes |
|----|--------|-----------|-------|
| 192.168.100.104 | Unknown | 2026-04-13 PM | **MISSING** — was all filtered, now gone ~2 days. |
| 192.168.100.251 | Unknown | 2026-04-13 PM | **MISSING** — was up Apr 9 with port 49152. Gone ~2 days. |
| 192.168.100.4 | LG Smart TV | 2026-04-09 | **Returned 2026-04-09** — port 3000 (LG smart TV http service) now responding. Was gone since ~2026-04-05. |
| 192.168.100.21 | TP-Link device | 2026-04-05 | **Gone 2026-04-08** — all ports filtered, no longer responding. |
| 192.168.100.23 | TP-Link/SZ Teleone | 2026-04-05 | **Gone 2026-04-09** — previously returned after absence. |
| 192.168.100.33 | Nagios/Linux host | 2026-04-05 AM | **Gone by PM** — SSH 22, Nagios NSCA 8008. Unknown device. |
| 192.168.100.50 | Unknown | 2026-04-05 AM | **Gone by PM** — port 49152 open. |
| 192.168.100.138 | Oraimo device | 2026-04-05 AM | **Gone by PM** — all ports closed. |
| 192.168.100.251 | Unknown | 2026-04-05 | **Gone 2026-04-09** — previously returned after ~2.5 weeks of silence. |
| 192.168.100.23 | TP-Link/SZ Teleone | 2026-04-02 | Gone by 2026-04-04 — port 8080 (http-proxy) no longer present |

### Last Scan
**2026-04-14 5:50 PM EAT (Apr 14 14:50 UTC)** — 7 hosts up.

**CHANGES from Apr 13 evening scan:**
- ✅ .224: **RETURNED 2026-04-14** — Oraimo device (5C:E8:B7:68:7F:38) back online after ~9 days absence.
- ✅ .105: **NEW 2026-04-14** — TP-Link device (F4:F2:6D:CE:85:D0) first appearance. All filtered.
- ⚠️ .104: **MISSING 2026-04-14** — Unknown device gone ~2 days. Was present Apr 13.
- ⚠️ .251: **MISSING 2026-04-14** — Unknown device gone ~2 days. Was present Apr 13.
- All services unchanged from prior scans (no new ports opened/closed)

### Security Concerns ⚠️
1. ⚠️ Router (.1): telnet port 23 is **OPEN** — 52+ days, unencrypted protocol, actively accessible. HIGH priority to disable.
2. ⚠️ .122: MySQL 5.7.44 exposed on LAN with autocommit + mysql_native_password.
3. ⚠️ .122: Port 9999 (abyss) open — HTTP service on unknown port.
4. 🔒 .4: LG Smart TV all filtered — sleeping.
5. ✅ .224: Oraimo device **RETURNED** after 9 days.
6. ✅ .105: NEW TP-Link device — all filtered, low priority.
7. ⚠️ .104, .251: **MISSING** — unknown devices gone ~2 days.

### This Machine Services (192.168.100.182)
- **:22** SSH (OpenSSH 8.9p1) — 0.0.0.0
- **:25** Postfix SMTP — all interfaces
- **:53** BIND 9.18.39 — all interfaces + IPv6
- **:80** HTTP — Duka DAO (Node.js/Express)
- Docker Swarm — ports 2377, 7946
- **Local only:** Ollama :11434, netdata :19999, Tor :9050, OpenClaw Gateway :18789-18792
- ZeroTier :9993, Cloudflare WARP, WireGuard-style tunnel (10.8.0.1)

### Docker Containers Running (updated 2026-04-05)

**Bridge Stack — ALL HEALTHY ✅ (fixed 2026-04-05)**
- `bridge_api` ✅ healthy — fixed `setDefaultLabel`→`setDefaultLabels` + `Hitogram`→`Histogram` (prom-client v15 API)
- `bridge_heartbeat` ✅ healthy — same prom-client API fix applied
- `bridge_tracker` ✅ healthy — same prom-client API fix applied
- `bridge_db` ✅ healthy — PostgreSQL 16, database `bridge_stack`
- `bridge-api-dev` 💀 Exited(255) — 13 days, abandoned dev version

### Crypto Stack — FIXED (2026-04-05)
- **crypto_nginx**: Was restart-looping 4 days — nginx.conf referenced stopped `crypto_prometheus` as upstream. Fixed by commenting out the `/metrics` location block in `/root/.openclaw/workspace/crypto_stack/config/nginx/nginx.conf`
- **crypto_loki**: Was restart-looping — corrupted WAL segments (missing 10-11 between 09 and 12). Fixed by clearing `/var/lib/docker/volumes/crypto_stack_crypto_logs_data/_data/wal/`
- All crypto containers now healthy ✅

**Other**
- `portainer` ✅ | `zerotier` ✅ | `crypto_loki` ✅ | `crypto_grafana` ✅
- `dao_wallet`, `gibsons_dash`, `stack-duka-dao-app-1`, `trusting_beaver` ❌ Exited

**Microservices Stack — DEPLOYED ✅ (2026-04-05)**
- Pull in progress: Elasticsearch ~2.5GB, Kafka ~2.5GB, Keycloak ~2.5GB (slow)
- 14 services: consul, kong, kong-db, keycloak, keycloak-db, app-db, redis,
  zookeeper, kafka, prometheus, grafana, elasticsearch, logstash, kibana,
  service-a, service-b, service-c
- Bugs fixed pre-deploy: network name mismatch, Keycloak port 8080→8180
- docker-compose.yml healthchecks fixed for kafka (was using non-existent kafka-topics.sh)
- See `TOOLS.md` → 🐳 Microservices Stack for full port map + credentials

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

### 🔥 TRENDING — "Settlement Layer Problem" (2026-03-24, STILL HOT)
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

## Oracle's Second Brain — Obsidian Blueprint

**Created:** 2026-03-22
**Location:** `/root/.openclaw/workspace/obsidian/`
**Last Expanded:** 2026-03-31 5:02 PM EAT

### Complete Mind Map Structure (7 Dimensions, 24 Files)

```
obsidian/
├── 00-GIBSON-SECOND-BRAIN.md     ← ROOT INDEX (master navigation)
├── 01-LIFE/
│   ├── Life-Overview.md          ← Health, goals, habits, vision ← UPDATED
│   └── Strategic-Roadmap.md      ← Long-term goals, 2026 plan ← UPDATED
├── 02-PROJECTS/
│   ├── MoltChain/
│   │   ├── MoltChain-Home.md     ← Ecosystem overview, strategy
│   │   ├── MoltChain-Status.md   ← Current karma, metrics ← UPDATED
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
│   └── Contact-Index.md          ← Key relationships, priorities ← UPDATED
├── 05-DECISIONS/
│   └── Decision-Log.md           ← Trade-off analysis, framework
├── 06-KNOWLEDGE/
│   └── Tools-Reference.md        ← Oracle capabilities + limits
└── 07-LOGS/
    ├── 2026-03-22-AM.md
    ├── 2026-03-22-PM.md
    ├── 2026-03-22-EVE.md
    ├── 2026-03-22-NIGHT.md
    ├── 2026-03-23-MON.md
    ├── 2026-03-24-TUE.md
    ├── 2026-03-30-AM.md
    ├── 2026-03-30-PM.md
    ├── 2026-03-30-EVE.md
    └── 2026-03-31-AM.md        ← NEW
```

---

## Current Gaps & Owner Action Items (as of 2026-03-31)

| Priority | Item | Days Pending | How to Fix |
|----------|------|--------------|------------|
| 🔴 | **M-PESA Balance Ksh 0.27** | TODAY | Top up to Ksh 1000+ minimum |
| 🔴 | Moltbook dashboard | 12+ days | https://www.moltbook.com/help/connect-account |
| 🟡 | RUFAS ATENG uncalled | 48+ days | Call 0723288566 TODAY |
| 🟡 | 0796591902 WhatsApp | 1 day | Open WhatsApp, respond |
| 🟡 | Google Storage 4% | 9+ days | myaccount.google.com → Storage |
| 🟡 | EcoBank inactive | UNADDRESSED | Paybill 700201, fund acct |
| 🟢 | ADB/Android | ✅ RECONNECTED | Keep USB cable connected |

---

## Cron Jobs Active

| Name | ID | Schedule | Status | Notes |
|------|----|---------|--------|-------|
| personal_assistant | ed7dd4d8-3762-430f-9fb9-e8f4d30faf19 | 30 min | ⚠️ errors | No channel configured |
| workspace-manager | b544d2e1-20b8-4b04-9297-a8cef4f06f64 | 5 min | ⚠️ errors | No channel configured |
| workspace-backup | 9eb3df4b-9bd6-483e-8ad6-be361fb6a1fb | 3 AM | ⏳ next 3AM | Daily backup script |
| Daily Network Scan | f5f01037-6942-4a6e-a562-8d9740a473cc | 6 AM EAT | ⚠️ error | OpenRouter rate limit / billing issue |
| MOLTCHAIN | 52530b65-a2c7-4fd5-a425-48947e1d4c38 | 30 min | ✅ ok | Growing ecosystem |

---

## Key Files

- `memory/moltchain_activity.md` — full MoltChain engagement log
- `MOLTCHAIN_DISCORD_SETUP.md` — Discord status and ecosystem map
- `memory/heartbeat-state.json` — periodic check timestamps
- `memory/security-YYYY-MM-DD.md` — daily security events
- `microservices_deploy.log` — live image pull progress
- `microservices_stack/` — Oracle's management dir (README.md, STACK.md, monitor.sh)

---

## Portainer — Docker Management UI
- **URL:** https://192.168.100.182:9443/#!/auth
- **Credentials:** admin / (temp password set on 2026-03-29)
- **Port:** :9443 (HTTPS, self-signed cert)

---

_Remember: I'm Gibson's second brain. What matters to him matters to me. Keep these files accurate and up to date._
