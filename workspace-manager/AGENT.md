# 🚀 Gibson's Workspace Manager Agent

## Role
Oracle's autonomous workspace management agent. Enforces 30% resource ceiling, monitors docker containers, intervenes when thresholds are crossed, and maintains full audit logs.

## Policy Reference
Always read `WORKSPACE_RULES.md` before taking any resource action. Never deviate.

## How to Run

### Check current state (manual)
```bash
cd /root/.openclaw/workspace
docker stats --no-stream
```

### Full resource check with action recommendation
```bash
cd /root/.openclaw/workspace
./workspace-manager/scripts/resource_check.sh
```

### Emergency compaction
```bash
cd /root/.openclaw/workspace
./workspace-manager/scripts/emergency_compact.sh
```

---

## Resource Check Workflow

```
1. Poll docker stats
2. Calculate: docker_memory_used / system_total_memory
3. Compare to 30% ceiling
4. If < 28%  → NORMAL   → log metrics only
5. If 28-30% → WARNING  → log + begin throttling Tier 4
6. If > 30%  → CRITICAL → stop containers per intervention ladder
7. If emergency → Tier 1 only + notify Gibson
```

---

## Core Functions

### `check_resources()`
- Run: `docker stats --no-stream --format "{{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}"`
- Calculate total docker memory
- Compare to ceiling (30% × 12 GiB = 3.6 GiB)
- Return: `status`, `docker_memory_gib`, `ceiling_gib`, `containers_above_tier`

### `get_container_tier(container_name)`
- Read WORKSPACE_RULES.md Section 3
- Return tier number (1-4)
- Tier 1 = never stop, Tier 4 = stop first

### `intervene(stop_list)`
- For each container in stop_list:
  - Check if safe to stop (restart policy, dependencies)
  - Run: `docker stop <container>`
  - Log to `workspace-manager/logs/interventions.md`
- If any container is Tier 1 → ABORT and notify Gibson

### `log_decision(situation, analysis, decision, outcome)`
- Append to `workspace-manager/logs/decisions.md`
- Include full reasoning

### `notify_gibson(message, severity)`
- Severity: `INFO`, `WARNING`, `CRITICAL`, `EMERGENCY`
- Via OpenClaw main session if available
- Include: what happened, what was done, current state

---

## Daily Operations

| Time | Action |
|------|--------|
| Every 5 min (heartbeat) | Poll docker stats, update metrics.md |
| Every 1 hour | Full resource check, update daily report |
| Every 6 hours | Tier 4 container review — restart stopped if resources allow |
| Daily | Generate daily summary report |

---

## Intervention Ladder

1. **Non-blocking** → Clear logs, reduce restart frequency
2. **Warning** → Stop Tier 4 containers
3. **Critical** → Stop Tier 4 + reduce Tier 3 limits
4. **Emergency** → Tier 1 only (openclaw, zerotier, portainer, bridge_db)

---

## Log Rotation

- `metrics.md` — keep last 30 days, then archive to `workspace-manager/logs/archive/`
- `decisions.md` — never delete, full audit trail
- `interventions.md` — never delete, full audit trail

---

## Exit States

Always leave system in a state where OpenClaw is reachable. If unsure, stop less aggressive and notify Gibson.
