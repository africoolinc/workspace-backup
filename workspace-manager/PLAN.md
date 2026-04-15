# Workspace Manager — Daily Operation Plan
**Generated:** 2026-04-14 09:54 AM EAT
**Based on:** `workspace_agent.md` blueprint + current WM Phase 2 implementation

---

## 📋 ASSESSMENT — What Exists vs What's Missing

### ✅ Already Built (Phase 2 Complete)
| Component | Location | Status |
|-----------|----------|--------|
| Resource Monitor | `services/resource_monitor/resource_monitor.sh` | ✅ Exists |
| Policy Engine | `services/policy_engine/policy_engine.sh` | ✅ Exists |
| Intervention Agent | `services/intervention_agent/intervention_agent.sh` | ✅ Exists |
| Logger Service | `services/logger_service/logger_service.sh` | ✅ Exists |
| Notifier Service | `services/notifier_service/notifier_service.sh` | ✅ Exists |
| Resource Check Script | `scripts/resource_check.sh` | ✅ Exists |
| Emergency Compact | `scripts/emergency_compact.sh` | ✅ Exists |
| Daily Report Generator | `scripts/report_generator.sh` | ✅ Exists |
| State Files | `state/current_metrics.json`, `state/current_phase.txt` | ✅ Exists |
| Logs | `logs/decisions.md`, `logs/interventions.md`, `logs/metrics.md` | ✅ Exist |
| Architecture Docs | `WORKSPACE_MANAGER.md`, `AGENT.md`, `WORKSPACE_RULES.md` | ✅ Exist |

### ❌ NOT Active — Missing cron jobs
The WM scripts are **installed but never triggered**. No cron jobs exist.

### ⚠️ Current System State (from last metrics)
- **Phase:** PHASE-3 (71.7% RAM, 61.8% Docker ceiling)
- **Oracle available:** 3.5 GiB (healthy ✅)
- **Docker containers:** 25 running
- **Load:** 64.8% of 4 cores
- **Last metrics:** 2026-04-13 09:55 PM (12 hours stale)

---

## 🎯 PLAN — Activate Daily Workflow

### CRON JOB 1 — Resource Check (Every 5 minutes)
**Purpose:** Continuous health monitoring — poll → policy → intervene → notify

```bash
# Activated 2026-04-14 — Oracle Workspace Manager
*/5 * * * * /root/.openclaw/workspace/workspace-manager/scripts/resource_check.sh >> /root/.openclaw/workspace/workspace-manager/logs/cron_resource_check.log 2>&1
```

### CRON JOB 2 — Daily Status Report (8:00 AM EAT)
**Purpose:** End-of-day summary saved to workspace status file

```bash
# Activated 2026-04-14 — Oracle Workspace Manager
0 8 * * * /root/.openclaw/workspace/workspace-manager/scripts/report_generator.sh >> /root/.openclaw/workspace/workspace-manager/logs/cron_daily_report.log 2>&1
```

### CRON JOB 3 — Tier 4 Restart Review (Every 6 hours)
**Purpose:** If PHASE-1 and Oracle healthy → restart stopped Tier 4 containers

```bash
# Activated 2026-04-14 — Oracle Workspace Manager
0 */6 * * * /root/.openclaw/workspace/workspace-manager/scripts/resource_check.sh --tier4-review >> /root/.openclaw/workspace/workspace-manager/logs/cron_tier4_review.log 2>&1
```

### REPORT OUTPUT — Daily Status File
**Location:** `/root/.openclaw/workspace/workspace-manager/reports/DAILY.md`

Format:
```
# Workspace Daily Report — YYYY-MM-DD

## Phase
PHASE-X | Load: X% | Docker: X% | Oracle: X GiB free

## Container Summary
| Tier | Running | Stopped |
|------|---------|---------|
| Tier 1 | X | 0 |
| Tier 2 | X | 0 |
| Tier 3 | X | X |
| Tier 4 | X | X |

## Interventions Today
- None / list of stops

## Alerts
- Any Gibson notifications

## Docker Stats
- Avg load: X
- Max load: X
- Docker mem: X GiB / X GiB ceiling

## Recommended Actions
- Any follow-up items for Gibson
```

---

## 📁 FILE STRUCTURE AFTER ACTIVATION

```
workspace-manager/
├── scripts/
│   ├── resource_check.sh       ← cron job 1 (every 5 min) + cron job 3 (every 6h)
│   └── report_generator.sh      ← cron job 2 (daily 8 AM)
├── state/
│   ├── current_metrics.json    ← updated every 5 min
│   └── current_phase.txt       ← updated every 5 min
├── logs/
│   ├── cron_resource_check.log  ← NEW: cron execution log
│   ├── cron_daily_report.log    ← NEW: daily report log
│   ├── cron_tier4_review.log    ← NEW: tier4 review log
│   ├── decisions.md
│   ├── interventions.md
│   └── metrics.md
└── reports/
    └── DAILY.md                ← updated daily 8 AM
```

---

## 🚦 ACTIVATION CHECKLIST

- [ ] 1. Add 3 cron jobs to OpenClaw cron scheduler
- [ ] 2. Run `resource_check.sh` manually → verify PHASE-3 state updated
- [ ] 3. Test `report_generator.sh` → verify DAILY.md written
- [ ] 4. Verify `current_metrics.json` timestamp updated
- [ ] 5. Commit all changes to git

---

## 📌 WORKSPACE RULES (from WORKSPACE_RULES.md)

**Binding thresholds:**
| Threshold | Value |
|-----------|-------|
| Docker memory ceiling | 50% of RAM (6.2 GiB on 12.35 GiB system) |
| Intervention load | 65% |
| Oracle reserve | 1.5 GiB minimum |
| Swap policy | Emergency only |

**Phase actions:**
| Phase | Trigger | Action |
|-------|---------|--------|
| 🟢 PHASE-1 | Load <65%, Docker <50% | Monitor only |
| 🟡 PHASE-2 | Load 65-80% or Docker 50-60% | Clear logs, reduce Tier 4 restart |
| 🟠 PHASE-3 | Load 80-100% or Docker 60-75% | Stop Tier 4, reduce Tier 3 |
| 🔴 PHASE-4 | Load >100% or Docker >75% or Oracle <500 MiB | EMERGENCY compact |

**Container tiers:**
- **Tier 1 (never stop):** openclaw, zerotier, portainer, bridge_db
- **Tier 2 (stop PHASE-3+):** bridge_api, bridge_heartbeat, bridge_tracker
- **Tier 3 (stop PHASE-3):** gibsons_dash, dao_wallet, crypto_*
- **Tier 4 (stop PHASE-2):** trusting_beaver, crypto_grafana, crypto_prometheus, crypto_redis, crypto_nginx, crypto_loki, stack-duka-dao-app-1

---

## ⚡ ONE-COMMAND ACTIVATION

```bash
openclaw cron add --name "workspace-manager-resource-check" --command "/root/.openclaw/workspace/workspace-manager/scripts/resource_check.sh" --schedule "*/5 * * * *" --channel heartbeat

openclaw cron add --name "workspace-manager-daily-report" --command "/root/.openclaw/workspace/workspace-manager/scripts/report_generator.sh" --schedule "0 8 * * *" --channel heartbeat

openclaw cron add --name "workspace-manager-tier4-review" --command "/root/.openclaw/workspace/workspace-manager/scripts/resource_check.sh --tier4-review" --schedule "0 */6 * * *" --channel heartbeat
```

---

**Built on:** Gibson's Workspace Manager Blueprint (AGI-inspired)
**Implementation:** Phase 2 — AI autonomy, active crons, daily reports
**Policy:** `WORKSPACE_RULES.md` (canonical threshold reference)
