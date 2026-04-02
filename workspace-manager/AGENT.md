# 🚀 Gibson's Workspace Manager Agent — AGENT.md

> **Oracle's autonomous workspace management agent.**
> Phase: **Phase 2** — AI autonomy, performance optimizations, problem-solving framework.

---

## Role

Oracle runs the Workspace Manager as its operational tool. WM enforces resource policy, manages docker containers, and keeps Gibson's infrastructure healthy — all fully documented.

---

## Policy Reference

Always read `WORKSPACE_RULES.md` before any resource action. **Never deviate.**
Thresholds in that file are binding on all automated decisions.

---

## Architecture

```
ORACLE (OpenClaw)
    ↓ reads logs + state
┌──────────────────────────────────────────────┐
│           Workspace Manager (WM)              │
│  ┌─────────────┐                             │
│  │  Resource   │ → state/current_metrics.json│
│  │  Monitor    │                             │
│  └──────┬────── ┘                             │
│         ↓ feeds                               │
│  ┌─────────────┐                             │
│  │  Policy     │ → state/current_phase.txt   │
│  │  Engine     │                             │
│  └──────┬────── ┘                             │
│         ↓ authorizes                           │
│  ┌─────────────┐                             │
│  │ Intervention│ → logs/decisions.md          │
│  │  Agent      │ → logs/interventions.md      │
│  └─────────────┘                             │
│         ↓ notifies                             │
│  ┌─────────────┐                             │
│  │  Notifier   │ → workspace-manager/.pending_│
│  │  Service    │   alert.json                 │
│  └─────────────┘                             │
└──────────────────────────────────────────────┘
```

---

## How to Run

### Full check (resource poll → policy → intervene if needed)
```bash
/root/.openclaw/workspace/workspace-manager/scripts/resource_check.sh
```

### Emergency compaction
```bash
/root/.openclaw/workspace/workspace-manager/scripts/emergency_compact.sh
```

### Run a specific service
```bash
# 1. Poll metrics
/root/.openclaw/workspace/workspace-manager/services/resource_monitor/resource_monitor.sh

# 2. Determine phase
/root/.openclaw/workspace/workspace-manager/services/policy_engine/policy_engine.sh

# 3. Intervene if needed
/root/.openclaw/workspace/workspace-manager/services/intervention_agent/intervention_agent.sh

# 4. Notify
/root/.openclaw/workspace/workspace-manager/services/notifier_service/notifier_service.sh emergency ...
```

---

## Decision Workflow (Per Problem-Solving Framework)

Every intervention follows this sequence:

```
STEP 1 — DESCRIBE
  What triggered the threshold?
  Container(s)? Load spike? Memory leak?

STEP 2 — IDENTIFY CAUSES
  docker stats history, container age, restart counts, FMEA

STEP 3 — COMPARE TO FACTS
  Current state vs WORKSPACE_RULES.md thresholds

STEP 4 — COLLECT MORE DATA
  container logs, dmesg, Oracle available memory

STEP 5 — CORRECTIVE ACTIONS
  Per intervention ladder (PHASE 1–4)

STEP 6 — VALIDATE
  Confirm memory freed, Oracle still healthy
```

All steps logged to: `workspace-manager/logs/decisions.md`

---

## Phase Definitions

| Phase | Trigger | Status | Action |
|-------|---------|--------|--------|
| PHASE-1 | Load < 65% AND Docker < 50% | 🟢 GREEN | Monitor only, log metrics |
| PHASE-2 | Load 65–80% OR Docker 50–60% | 🟡 YELLOW | Advisory — clear logs, reduce Tier 4 restart |
| PHASE-3 | Load 80–100% OR Docker 60–75% | 🟠 ORANGE | Stop all Tier 4, reduce Tier 3 limits |
| PHASE-4 | Load > 100% OR Docker > 75% OR Oracle < 500 MiB | 🔴 RED | Tier 1 only — emergency compact |

---

## Container Priority Tiers

**Tier 1 — CRITICAL (never stop without user approval)**
- openclaw, zerotier, portainer, bridge_db

**Tier 2 — ESSENTIAL (stop only PHASE-3+)**
- bridge_api, bridge_heartbeat, bridge_tracker

**Tier 3 — IMPORTANT (stop at PHASE-3)**
- gibsons_dash, dao_wallet, crypto_blockchain, crypto_postgres, crypto-register-*

**Tier 4 — BACKGROUND (stop at PHASE-2)**
- trusting_beaver, crypto_grafana, crypto_prometheus, crypto_redis, crypto_nginx, crypto_loki, stack-duka-dao-app-1, crypto_*, crypto_dns, crypto_mpesa, crypto_phone

---

## Cron Schedule

| Job | Schedule | What it does |
|-----|----------|-------------|
| `workspace-manager-resource-check` | Every 5 min | Full pipeline: poll → policy → intervene → notify |
| `workspace-manager-daily-report` | Daily 8 AM | Summary: avg/max load, docker mem, interventions |
| `workspace-manager-tier4-review` | Every 6 hours | Restart stopped Tier 4 if PHASE-1 and Oracle healthy |

---

## Logging Standards

All logs in `workspace-manager/logs/`:
- **decisions.md** — full reasoning for every action taken or declined (never delete)
- **interventions.md** — every stop/throttle event (never delete)
- **metrics.md** — periodic resource snapshots (archive after 30 days)
- **notifier_alerts.md** — all Gibson alerts

Log format: `| timestamp | field1 | field2 | ...`
Log writes: append-only, async via logger_service buffer

---

## Performance Targets

| Metric | Target |
|--------|--------|
| Decision latency (poll → action) | < 500 ms |
| Alert delivery | < 2 s |
| Docker stats poll | Non-blocking |
| Memory footprint | < 50 MiB |

---

## Oracle Override

Any WM decision can be overridden by Gibson through Oracle.
To override: message Oracle directly — "stop the intervention" or "don't stop [container]"

WM respects Oracle's judgment. WM logs all overrides for learning.

---

## Exit States

WM always leaves the system in a state where Oracle is reachable.
If uncertain: act less aggressive, notify Gibson, log it.

---

**Built on:** Gibson's Workspace Manager Blueprint (AGI-inspired)
**Policy:** `WORKSPACE_RULES.md`
**Canonical:** `WORKSPACE_MANAGER.md`
