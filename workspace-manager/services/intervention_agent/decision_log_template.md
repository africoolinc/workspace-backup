# Decision Log Template — Gibson's Workspace Manager
> Used by: intervention_agent
> Format: per-incident markdown table

---

## Incident: `[INCIDENT-ID]` — `[DATE]`

### Context
- **Phase:** PHASE-`[1-4]`
- **Trigger:** What threshold was crossed?
- **System load:** `[X] / 4 cores ([Y]%)`
- **Docker memory:** `[X] GiB / 6.0 GiB ceiling ([Z]%)`
- **Oracle available:** `[X] GiB`
- **Containers running:** `[N]`

---

## Problem-Solving Framework

### STEP 1 — DESCRIBE
> What happened? What/where/when?

```
[Free-text description of the problem]
```

### STEP 2 — IDENTIFY CAUSES
> Why did this happen? FMEA analysis.

| Possible Cause | Likelihood | Impact | Root Cause? |
|---------------|-----------|--------|-------------|
| [cause 1] | H/M/L | H/M/L | Y/N |
| [cause 2] | H/M/L | H/M/L | Y/N |
| [cause 3] | H/M/L | H/M/L | Y/N |

**Identified root cause:** [description]

### STEP 3 — COMPARE TO FACTS
| Metric | Current | Threshold | Status |
|--------|---------|-----------|--------|
| Docker memory | X GiB | 6.0 GiB | OK / EXCEEDED |
| System load | X (Y%) | 65% | OK / EXCEEDED |
| Oracle available | X GiB | 1.5 GiB | OK / EXCEEDED |

### STEP 4 — COLLECT MORE DATA
- Container logs: `[relevant log lines]`
- Host processes: `[top processes]`
- Recent events: `[docker events]`

### STEP 5 — CORRECTIVE ACTIONS

| Action | Target | Reason | Result |
|--------|--------|--------|--------|
| [action] | [container/tier] | [why] | OK/FAILED |

### STEP 6 — VALIDATE

| Metric | Pre | Post | Delta |
|--------|-----|------|-------|
| Docker memory | X GiB | Y GiB | -Z GiB |
| System load | X | Y | -Z |
| Oracle available | X GiB | Y GiB | +Z GiB |
| Containers stopped | N | M | K |

**Outcome:** RESOLVED / PERSISTING / ESCALATED

---

## Decision Record

- **Decided to:** [what was done]
- **Alternatives considered:** [what else was possible]
- **Override by Oracle/Gibson:** YES / NO
- **Learning:** [what was learned for next time]

---
