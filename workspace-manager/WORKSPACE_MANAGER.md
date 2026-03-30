# 🏗️ Gibson's Workspace Manager — Architecture & Documentation

> Modular AI-driven workspace management system. Built on the Workspace Manager Blueprint.
> Phase: **MVP** — Core services, clean code, basic APIs.

---

## 1. Overview

The Workspace Manager (WM) is an Oracle sub-agent responsible for:
1. **Monitoring** — Real-time tracking of docker container resources
2. **Enforcing** — The 30% resource ceiling policy from `WORKSPACE_RULES.md`
3. **Intervening** — Auto-throttling or stopping containers when thresholds are crossed
4. **Logging** — All decisions and actions documented for audit and learning
5. **Reporting** — Proactive alerts and summaries to Gibson

---

## 2. Microservices Design

WM follows a microservices-inspired modular design even though it runs as a single agent:

| Module | Responsibility |
|--------|---------------|
| `resource_monitor` | Polls docker stats, tracks memory/CPU over time |
| `policy_engine` | Evaluates current state against `WORKSPACE_RULES.md` |
| `intervention_agent` | Decides and executes throttling/stopping actions |
| `logger` | Structured audit log of all decisions and actions |
| `notifier` | Alerts Gibson when intervention occurs |

Each module has a single responsibility. Communication via shared state (files).

---

## 3. Decision Framework (Problem-Solving)

When a threshold is crossed:

```
DESCRIBE → Identify container(s) causing exceedance
     ↓
IDENTIFY CAUSES → Memory growth trend, container age, restart patterns
     ↓
COMPARE TO FACTS → Current vs ceiling, tier priority, business impact
     ↓
COLLECT MORE DATA → Recent logs, container health, dependency chain
     ↓
CORRECTIVE ACTION → Per intervention ladder (WORKSPACE_RULES.md Section 4)
     ↓
VALIDATE → Check memory freed, verify OpenClaw still healthy
```

All decisions logged with: `timestamp`, `trigger`, `action_taken`, `result`, `openclaw_status`.

---

## 4. Clean Code Standards

- Meaningful names — no abbreviations (`container_memory_usage`, not `cmem`)
- Small functions — one job each
- Comments explain intent, not code
- No magic numbers — all thresholds in `WORKSPACE_RULES.md`
- Error handling — graceful degradation, never crash OpenClaw to save a container
- Unit testable — pure functions where possible

---

## 5. Performance

- Async polling of docker stats (non-blocking)
- In-memory state with file fallback
- Logs written in append mode
- Response targets: decisions < 500ms, alerts < 2s

---

## 6. Log Locations

| Log | Purpose |
|-----|---------|
| `workspace-manager/logs/interventions.md` | All throttle/stop decisions |
| `workspace-manager/logs/metrics.md` | Periodic resource snapshots |
| `workspace-manager/logs/decisions.md` | Full decision reasoning log |
| `workspace-manager/reports/DAILY.md` | Daily summary report |

---

## 7. Phase Roadmap

- [x] Phase 1: MVP — Policy engine, monitor, basic interventions
- [ ] Phase 2: AI autonomy, predictive caching of containers
- [ ] Phase 3: Full generality — multi-environment support
- [ ] Phase 4: Self-improving AGI features

---

_This document is the canonical reference for the Workspace Manager._
