# 🧠 Gibson's Workspace Manager — Operational Rules
> **Strict policy. Do not deviate. Override requires explicit user approval.**

---

## 1. Resource Ceiling Policy

| Resource | Hard Limit | OpenClaw Reserve |
|----------|-----------|-----------------|
| **Memory** | **30% of available** (~3.6 GiB on 12 GiB system) | ~2 GiB minimum at all times |
| **CPU** | 30% of total cores | OpenClaw never starved |
| **Disk I/O** | Non-blocking threshold only | N/A |
| **Swap** | Emergency only — never routine | N/A |

**Why 30%?** OpenClaw must always have headroom to manage the system. If OpenClaw runs out of resources, nothing gets managed.

---

## 2. Docker Workload Budget

**Enforced ceiling:** Docker containers collectively must **never exceed 30% system memory**.

Current system has 12 GiB RAM:
- OpenClaw reserve: ~2 GiB minimum
- Docker ceiling: ~3.6 GiB
- System kernel/overhead: ~500 MiB
- **Free buffer: ~5.9 GiB (for bursts, spikes)**

### Intervention Triggers
| Condition | Action |
|-----------|--------|
| Docker memory usage > 28% (~3.36 GiB) | ⚠️ WARNING — begin throttling non-critical containers |
| Docker memory usage > 30% (~3.6 GiB) | 🚨 CRITICAL — auto-throttle or stop non-essential containers |
| OpenClaw available memory < 1 GiB | 🛑 EMERGENCY — halt all non-essential workloads |
| System memory pressure detected | 🚨 CRITICAL — invoke emergency compaction |

---

## 3. Container Priority Tiers

### Tier 1 — Critical (NEVER STOP without explicit user approval)
- `openclaw` (the agent itself)
- `zerotier` (network connectivity)
- `portainer` (management interface)

### Tier 2 — Essential (Stop only in EMERGENCY)
- `bridge_api` — bridge infrastructure
- `bridge_db` — database
- `bridge_heartbeat` — monitoring
- `bridge_tracker` — tracking

### Tier 3 — Important (Stop at WARNING threshold)
- `gibsons_dash` — dashboard
- `dao_wallet` — wallet
- `crypto-register-api` / `crypto-register-frontend`
- `trading-api`

### Tier 4 — Background (Stop at WARNING, stay stopped at CRITICAL)
- `crypto_stack-options-bot-1`
- `trusting_beaver`
- `crypto_resolver`
- `crypto_prometheus`
- `crypto_traefik`
- `stack-duka-dao-app-1`
- `bridge-api-dev`
- `crypto_redis`

---

## 4. Throttling & Compaction Actions (in order)

### Step 1 — Non-blocking (WARNING)
- Reduce container restart policies for Tier 4
- Lower log verbosity in containers that support it
- Clear old logs and dangling docker resources

### Step 2 — Active throttling (WARNING persists)
- Stop Tier 4 containers one by one
- Reduce memory limits on Tier 3 containers via `docker update`

### Step 3 — Aggressive (CRITICAL)
- Stop all Tier 4 containers
- Reduce memory limits on Tier 3 containers
- Stop Tier 2 containers except `bridge_api` and `bridge_db`

### Step 4 — Emergency (EMERGENCY)
- Only `openclaw`, `zerotier`, `portainer`, `bridge_db` remain
- All other containers stopped
- Notify user immediately

---

## 5. OpenClaw Resource Protection

OpenClaw (this agent) MUST maintain:
- **Minimum 1 GiB available memory** — never consumed by managed workloads
- **Minimum 10% CPU** — never fully starved
- **Disk space** for logs, memory files, workspace

If OpenClaw cannot respond due to resource starvation, the system has failed its primary objective.

---

## 6. Enforcement

These rules are **binding** on all automated actions. Any deviation requires explicit user approval in writing (chat message minimum).

Cron jobs and background agents must respect these limits. The Workspace Manager Agent enforces these rules.

---

_Updated: 2026-03-22_
_Reason: Initial policy — 30% docker ceiling on 12 GiB system_
