# WORKSPACE_RULES.md — Gibson's Workspace Manager Policy
> **STRICT POLICY. Zero deviation without explicit user approval.**
> Last updated: 2026-03-31 | System: 12 GiB RAM, 4 cores, i3-4130

---

## 1. Resource Ceiling Policy

| Metric | Limit | Notes |
|--------|-------|-------|
| **Docker Memory** | **≤ 50% system memory** (~6.0 GiB on 12 GiB) | Hard ceiling |
| **Intervention Threshold** | **≥ 65% system load average** (load avg / cores) | Auto-intervene |
| **Oracle Reserve** | ≥ 1.5 GiB available memory always | Never consumable |
| **CPU Ceiling** | 80% of cores under sustained load | Oracle never starved |
| **Swap** | Emergency only — never routine ops | Kernel last resort |

**Why 50% Docker / 65% load?**  
- 50% gives Docker serious headroom (6 GiB) while Oracle keeps 6 GiB for itself.
- 65% load on 4 cores = sustained pressure requiring intervention.
- Below thresholds → monitor only. At/above → execute intervention ladder.

---

## 2. System Profile

| Property | Value |
|----------|-------|
| Hostname | ahie |
| RAM | 12 GiB DDR3 |
| CPU | Intel i3-4130 (4 threads) |
| OS | Linux 6.8.0-106-generic |
| Docker Memory Ceiling | 6.0 GiB |
| Oracle Minimum Reserve | 1.5 GiB |
| User Buffers / Headroom | 4.5 GiB |

---

## 3. Container Priority Tiers

### Tier 1 — CRITICAL (NEVER stop without explicit user approval)
- `openclaw` — the agent itself
- `zerotier` — network tunnel
- `portainer` — management UI
- `bridge_db` — persistent data

### Tier 2 — ESSENTIAL (Stop only in PHASE-3 or above)
- `bridge_api` — bridge REST API
- `bridge_heartbeat` — uptime monitor
- `bridge_tracker` — tracker service

### Tier 3 — IMPORTANT (Stop at PHASE-2 threshold)
- `gibsons_dash` — Gibson's dashboard
- `dao_wallet` — DAO wallet interface
- `crypto-register-api` / `crypto-register-frontend` — registration stack
- `crypto_blockchain` — blockchain node
- `crypto_postgres` — database

### Tier 4 — BACKGROUND (Stop at PHASE-1, stay stopped at PHASE-2+)
- `trusting_beaver` — background resolver
- `crypto_grafana` — monitoring UI
- `crypto_prometheus` — metrics DB
- `crypto_traefik` — reverse proxy
- `crypto_redis` — cache
- `crypto_cloudflare` — tunnel agent
- `crypto_dns` / `crypto_mpesa` / `crypto_phone` — aux services
- `stack-duka-dao-app-1` — Duka DAO app
- `crypto_loki` — log aggregator
- `crypto_nginx` — nginx gateway

---

## 4. Intervention Ladder

### PHASE 1 — MONITORING (System load < 65% AND Docker < 50%)
- Poll every 5 minutes
- Log metrics to `workspace-manager/logs/metrics.md`
- No action required
- **Status: GREEN**

### PHASE 2 — ADVISORY (System load 65–80% OR Docker 50–60%)
- Notify Gibson of elevated state
- Begin collecting additional diagnostics
- Reduce Tier 4 container restart frequency
- Clear old logs and dangling docker resources
- **Status: YELLOW**

### PHASE 3 — ACTIVE INTERVENTION (System load 80–100% OR Docker 60–75%)
- Stop all Tier 4 containers (one by one, verify freed memory after each)
- Reduce memory limits on Tier 3 containers via `docker update`
- Pause non-essential services
- Log every action with full reasoning
- **Status: ORANGE**

### PHASE 4 — EMERGENCY (System load > 100% OR Docker > 75% OR Oracle < 1.5 GiB free)
- Only Tier 1 containers remain running
- Attempt emergency compaction of Docker memory
- If Oracle available memory < 500 MiB → full emergency mode
- Notify Gibson immediately with full situation report
- **Status: RED**

---

## 5. Oracle (OpenClaw) Resource Protection

Oracle MUST maintain at all times:
- **≥ 1.5 GiB available memory** — absolute minimum
- **≥ 10% CPU time** — never fully starved
- **Disk space** — 500 MiB minimum for logs/workspace

If Oracle cannot respond → **system has failed its primary objective**.
All automation subordinate to Oracle's health.

---

## 6. Enforcement

| Rule | Binding? |
|------|----------|
| Never stop Tier 1 without explicit user approval | **ABSOLUTE** |
| Never let Docker exceed 50% memory ceiling | **ABSOLUTE** |
| Oracle reserve < 1.5 GiB → emergency protocol | **ABSOLUTE** |
| Intervention ladder sequencing | **BINDING** |
| Logging every decision and action | **BINDING** |

Any deviation requires explicit written approval (chat message minimum).

---

## 7. Performance Standards

| Metric | Target |
|--------|--------|
| Decision latency (resource check → action) | < 500 ms |
| Alert delivery to Gibson | < 2 s |
| Docker stats polling | Non-blocking |
| Log writes | Append-only, async |
| Response time for Gibson queries | < 5 s |

---

## 8. Clean Code Standards (Workspace Manager)

- Meaningful names — no abbreviations (`container_memory_usage_gib`, not `cmem`)
- Small functions — one job each
- Comments explain **intent**, not mechanics
- No magic numbers — all thresholds in this file
- Error handling — graceful degradation, never crash Oracle to save a container
- F.I.R.S.T. principles for any testable code

---

## 9. Problem-Solving Framework (Per Intervention)

```
STEP 1 — DESCRIBE
  What container(s) triggered the threshold?
  What is the current system state? (load, memory, CPU)
  When did it start? What changed recently?

STEP 2 — IDENTIFY CAUSES
  Collect: docker stats history, container age, restart counts
  Analyze: memory growth trend, I/O patterns, dependency chain
  FMEA: list all possible causes ranked by likelihood

STEP 3 — COMPARE TO FACTS
  Current load average vs ceiling
  Docker memory used vs 50% ceiling
  Tier priority vs business impact

STEP 4 — COLLECT MORE DATA
  Recent container logs
  System dmesg /var/log/syslog entries
  Oracle available memory snapshot

STEP 5 — CORRECTIVE ACTIONS
  Per intervention ladder above
  Document every step with timestamp and reasoning

STEP 6 — VALIDATE
  Verify memory/CPU freed after each action
  Confirm Oracle still healthy and responsive
  Log final state post-intervention
```

---

## 10. Cron Schedule

| Job | Schedule | Purpose |
|-----|----------|---------|
| `workspace-manager-resource-check` | Every 5 min | Poll + log + intervene if needed |
| `workspace-manager-daily-report` | Daily 8 AM | Full metrics + tier health report |
| `workspace-manager-tier4-review` | Every 6 hours | Restart stopped Tier 4 if load allows |

---

_This file is the single source of truth for workspace resource policy._
_Any change must be committed to git and announced to Gibson._
