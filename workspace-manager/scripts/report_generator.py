#!/usr/bin/env python3
"""
Daily Report Generator — Gibson's Workspace Manager
Phase: Phase 2

Responsibility: Generate a structured daily status report from workspace state,
save it to reports/DAILY.md, and optionally push a summary to Oracle's daily log.
"""
import os
import json
from datetime import datetime, timezone

WORKSPACE = os.environ.get('WORKSPACE', '/root/.openclaw/workspace')
WM_DIR = os.path.join(WORKSPACE, 'workspace-manager')
STATE_DIR = os.path.join(WM_DIR, 'state')
LOGS_DIR = os.path.join(WM_DIR, 'logs')
REPORTS_DIR = os.path.join(WM_DIR, 'reports')
MEMORY_DIR = os.path.join(WORKSPACE, 'memory')

TODAY = datetime.now(timezone.utc).strftime('%Y-%m-%d')
TODAY_EAT = datetime.now().strftime('%Y-%m-%d')

def get_metrics():
    """Load current metrics."""
    try:
        with open(os.path.join(STATE_DIR, 'current_metrics.json')) as f:
            return json.load(f)
    except Exception:
        return None

def get_phase():
    """Read current phase."""
    try:
        with open(os.path.join(STATE_DIR, 'current_phase.txt')) as f:
            return f.read().strip()
    except Exception:
        return "UNKNOWN"

def parse_interventions_today():
    """Extract today's interventions from logs/interventions.md."""
    log_file = os.path.join(LOGS_DIR, 'interventions.md')
    lines = []
    try:
        with open(log_file) as f:
            content = f.read()
        # Find rows for today
        import re
        rows = re.findall(rf'{TODAY}.*', content)
        return rows[-5:]  # last 5
    except Exception:
        return []

def parse_metrics_history():
    """Get last 24h from metrics.md."""
    log_file = os.path.join(LOGS_DIR, 'metrics.md')
    entries = []
    try:
        with open(log_file) as f:
            content = f.read()
        import re
        rows = re.findall(r'\|.*PHASE-.*\|', content)
        for row in rows[-24:]:  # last 24 entries
            entries.append(row.strip())
        return entries
    except Exception:
        return []

def count_containers():
    """Count running and stopped containers."""
    try:
        result = os.popen("docker ps --format '{{.Names}}' 2>/dev/null").readlines()
        running = len(result)
        # Count total from docker-compose
        total_result = os.popen("docker ps -a --format '{{.Names}}' 2>/dev/null").readlines()
        total = len(total_result)
        return running, total - running, total
    except Exception:
        return 0, 0, 0

def get_docker_stats():
    """Get docker memory stats from current metrics."""
    m = get_metrics()
    if not m:
        return "N/A", "N/A"
    d = m.get('docker', {})
    used_gib = d.get('memory_used_gib', 0)
    ceiling_gib = d.get('ceiling_gib', 0)
    pct = d.get('usage_percent_of_ceiling', 0)
    return f"{used_gib:.2f} GiB / {ceiling_gib:.2f} GiB ({pct:.1f}%)", pct

def get_load_stats():
    """Get load average from current metrics."""
    m = get_metrics()
    if not m:
        return "N/A", "N/A"
    s = m.get('system', {})
    load = s.get('load_average_1m', 0)
    pct = s.get('load_percent_of_cores', 0)
    return f"{load} (1m avg) / {pct:.1f}% of cores", pct

def generate_report():
    phase = get_phase()
    phase_emoji = {
        "PHASE-1": "🟢 PHASE-1",
        "PHASE-2": "🟡 PHASE-2",
        "PHASE-3": "🟠 PHASE-3",
        "PHASE-4": "🔴 PHASE-4",
    }.get(phase, phase)

    m = get_metrics()
    oracle_gib = "N/A"
    mem_pct = "N/A"
    if m:
        oracle_gib = m.get('memory', {}).get('oracle_available_bytes', 0) / 1073741824
        mem_pct = m.get('memory', {}).get('usage_percent', 0)

    running, stopped, total = count_containers()
    docker_str, docker_pct = get_docker_stats()
    load_str, load_pct = get_load_stats()

    interventions = parse_interventions_today()
    intervention_lines = "\n".join(f"- `{row}`" for row in interventions) or "- No interventions today"

    report = f"""# Workspace Daily Report — {TODAY_EAT}

> Generated: {datetime.now().strftime('%I:%M %p %Z')} (EAT)

## Overall Status

| Metric | Value |
|--------|-------|
| **Phase** | {phase_emoji} |
| **Load** | {load_str} |
| **Docker Memory** | {docker_str} |
| **Oracle Available RAM** | {oracle_gib:.1f} GiB |
| **System Memory** | {mem_pct:.1f}% used |

## Container Summary

| Category | Count |
|----------|-------|
| Running | {running} |
| Stopped | {stopped} |
| Total tracked | {total} |

## Interventions Today

{intervention_lines}

## 24-Hour Metrics History

```
| Timestamp | Phase | Mem% | Docker% | Load% | Load(1m) | DockerGiB | OracleGiB |
|-----------|-------|------|---------|-------|----------|-----------|-----------|
```
*Recent entries from `logs/metrics.md` — see full log for details.*

## Workspace Health

| Area | Status | Notes |
|------|--------|-------|
| Docker | {'✅ Healthy' if docker_pct < 75 else '⚠️ High'} | {docker_str} |
| Memory | {'✅ Normal' if mem_pct < 80 else '⚠️ High'} | {mem_pct:.1f}% used |
| Oracle | {'✅ Available' if oracle_gib > 1.5 else '🔴 Low'} | {oracle_gib:.1f} GiB free |
| Containers | {'✅ All up' if stopped == 0 else '⚠️ Some stopped'} | {running}/{total} running |

## Action Items

"""
    # Add action items based on phase
    actions = []
    if phase in ("PHASE-3", "PHASE-4"):
        actions.append("⚠️ Review PHASE-3/4 intervention — check `logs/interventions.md`")
    if stopped > 0:
        actions.append(f"📋 {stopped} container(s) stopped — will auto-restart when load permits")
    if mem_pct > 80:
        actions.append("💾 High memory — consider reviewing Tier 3/4 containers")
    if not actions:
        actions.append("✅ No immediate action needed — workspace is healthy")

    report += "\n".join(f"- {a}" for a in actions)
    report += f"\n\n---\n*Generated by Oracle Workspace Manager — {datetime.now().isoformat()}*"

    return report

def main():
    report = generate_report()

    # Save to DAILY.md
    os.makedirs(REPORTS_DIR, exist_ok=True)
    daily_path = os.path.join(REPORTS_DIR, 'DAILY.md')
    with open(daily_path, 'w') as f:
        f.write(report)

    # Also save a dated copy
    dated_path = os.path.join(REPORTS_DIR, f'DAILY_{TODAY}.md')
    with open(dated_path, 'w') as f:
        f.write(report)

    # Append to memory/metrics if needed
    print(f"Report saved to: {daily_path}")
    print(report)

if __name__ == '__main__':
    main()
