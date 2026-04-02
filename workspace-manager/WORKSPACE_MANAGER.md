# 🚀 Workspace Manager — Gibson's AI-Driven Workspace Orchestrator

> **Autonomous. Modular. AGI-inspired.**
> Phase: **Phase 2** — AI autonomy, performance optimizations, problem-solving framework.
> Integrates: Oracle (OpenClaw) as Core Orchestrator.

---

## 1. Vision

Workspace Manager (WM) is Oracle's autonomous workspace management agent — the system that watches over Gibson's docker ecosystem, enforces resource policy, troubleshoots issues, and keeps everything running. It thinks, it acts, it logs everything.

Built on the Gibson's Workspace Manager Blueprint:
- **High Autonomy** — automates setup, dependency resolution, adaptation
- **High Generality** — supports web, data, crypto, blockchain environments
- **High Intelligence** — optimizes, predicts, suggests improvements
- **AGI-Inspired** — adaptive foresight, transparent decisions, user overrides

---

## 2. Architecture — Microservices Design

WM runs as a set of modular services coordinated by Oracle:

```
┌─────────────────────────────────────────────────────────────┐
│                    ORACLE (Core Orchestrator)                │
│         OpenClaw AI Engine — reasoning, decisions          │
├─────────────┬─────────────┬──────────────┬────────────────┤
│  Resource   │   Policy    │ Intervention │    Logger      │
│  Monitor    │   Engine    │    Agent     │    Service     │
│  Service    │   Service   │    Service   │    Service     │
├─────────────┴─────────────┴──────────────┴────────────────┤
│              Docker Stats API  ·  /proc/meminfo  ·  uptime  │
└─────────────────────────────────────────────────────────────┘
```

### Service Responsibilities

| Service | Single Job | Boundaries |
|---------|-----------|------------|
| `resource_monitor` | Poll system + docker stats every 5 min | Reads only, no side effects |
| `policy_engine` | Evaluate state vs WORKSPACE_RULES.md | Decision logic only |
| `intervention_agent` | Execute throttling/stopping actions | Acts only when authorized |
| `logger_service` | Structured append-only logs | Writes only, never modifies |
| `notifier_service` | Alert Gibson via Oracle | Read-only on system state |

### Communication
All services communicate via shared state files:
- `/workspace/workspace-manager/state/current_metrics.json`
- `/workspace/workspace-manager/state/current_phase.txt`
- `/workspace/workspace-manager/state/intervention_queue.json`

---

## 3. Development Standards

Followed from Blueprint Section 3 — Clean Code:

- **Names**: Meaningful, no abbreviations, no magic numbers
- **Functions**: Small, single responsibility, minimal arguments
- **Comments**: Explain intent — `// Calculate remaining headroom before acting`
- **Formatting**: Consistent blank-line separation
- **Error Handling**: Graceful degradation — if one service fails, others continue
- **Tests**: F.I.R.S.T. principles for any testable logic

---

## 4. Performance Optimizations (Blueprint Section 4)

| Optimization | Implementation |
|-------------|---------------|
| Pagination | Large log files read page-by-page (100 lines/page) |
| Async Logging | Buffer writes, flush every 30s or on phase change |
| Caching | `current_metrics.json` cached 60s, TTL 30s |
| Payload Compression | GZIP old archived logs (> 7 days) |
| Connection Reuse | Docker stats socket kept open between polls |
| Response Target | Decisions < 500ms, alerts < 2s |

---

## 5. Problem-Solving Framework

Embedded in intervention_agent for autonomous troubleshooting:

```
DESCRIBE ──→ Identify what/where/when of the problem
    ↓
IDENTIFY CAUSES ──→ Collect docker stats, logs, FMEA analysis
    ↓
COMPARE TO FACTS ──→ Current state vs thresholds in WORKSPACE_RULES.md
    ↓
COLLECT MORE DATA ──→ Additional diagnostics if cause unclear
    ↓
CORRECTIVE ACTIONS ──→ Execute intervention ladder (PHASE 1–4)
    ↓
VALIDATE ──→ Confirm memory freed, Oracle healthy
```

Full template in `services/intervention_agent/decision_log_template.md`.

---

## 6. Phase Roadmap

| Phase | Status | Contents |
|-------|--------|----------|
| Phase 1 | ✅ MVP | Policy engine, resource monitor, basic interventions |
| Phase 2 | 🚀 CURRENT | AI autonomy, async logging, caching, performance optimizations |
| Phase 3 | 📋 NEXT | Predictive container pre-warming, multi-environment support |
| Phase 4 | 📋 FUTURE | Self-improving, pattern learning, full AGI features |

---

## 7. Service File Map

```
workspace-manager/
├── WORKSPACE_MANAGER.md          ← This file (architecture overview)
├── WORKSPACE_RULES.md            ← Canonical policy (thresholds, tiers)
├── services/
│   ├── resource_monitor/
│   │   └── resource_monitor.sh
│   ├── policy_engine/
│   │   └── policy_engine.sh
│   ├── intervention_agent/
│   │   ├── intervention_agent.sh
│   │   └── decision_log_template.md
│   ├── logger_service/
│   │   └── logger_service.sh
│   └── notifier_service/
│       └── notifier_service.sh
├── scripts/
│   ├── resource_check.sh         ← Entry point (cron/heartbeat)
│   ├── emergency_compact.sh      ← PHASE-4 emergency actions
│   └── report_generator.sh        ← Daily report generation
├── state/                        ← Shared inter-service state
│   ├── current_metrics.json
│   ├── current_phase.txt
│   └── intervention_queue.json
├── logs/
│   ├── interventions.md          ← All throttle/stop events
│   ├── decisions.md              ← Full reasoning for every action
│   └── metrics.md                ← Periodic resource snapshots
└── reports/
    ├── DAILY.md                  ← Daily summary
    └── INCIDENT_YYYY-MM-DD.md    ← Per-incident deep-dive reports
```

---

## 8. Oracle Integration

Oracle (OpenClaw) is the **Core Orchestrator**. WM is Oracle's tool.
- Oracle reads WM logs and state to inform its reasoning
- WM acts on Oracle's behalf when thresholds are crossed
- Gibson can override any WM decision by speaking to Oracle
- WM never acts without consulting WORKSPACE_RULES.md first

---

## 9. Exit States

WM always leaves the system in a state where Oracle is reachable.
- If uncertain → stop less aggressive, notify Gibson
- Never sacrifice Oracle availability to save a container
- Full emergency protocol documented in `WORKSPACE_RULES.md Section 4 PHASE 4`

---

_Canonical reference: `WORKSPACE_RULES.md`_
_Built on: Gibson's Workspace Manager Blueprint (AGI-inspired)_
