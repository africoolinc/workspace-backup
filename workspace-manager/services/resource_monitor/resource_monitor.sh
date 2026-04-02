#!/usr/bin/env python3
"""
Resource Monitor Service — Gibson's Workspace Manager
Phase: Phase 2
Responsibility: Non-blocking poll of system + docker resource metrics
Performance: < 3 seconds end-to-end via Python (no bash arithmetic issues)
"""
import subprocess
import os
import re
import json
from datetime import datetime

WORKSPACE = os.environ.get('WORKSPACE', '/root/.openclaw/workspace')
STATE_DIR = os.path.join(WORKSPACE, 'workspace-manager/state')
METRICS_FILE = os.path.join(STATE_DIR, 'current_metrics.json')
LAST_METRICS_FILE = os.path.join(STATE_DIR, 'last_metrics.json')
LOG_FILE = os.path.join(WORKSPACE, 'workspace-manager/logs/metrics.md')

# =============================================================================
# Constants
# =============================================================================

with open('/proc/meminfo') as f:
    content = f.read()
mem_total_kb = int([l for l in content.split('\n') if l.startswith('MemTotal:')][0].split()[1])

SYSTEM_MEMORY_BYTES = mem_total_kb * 1024
DOCKER_CEILING_BYTES = SYSTEM_MEMORY_BYTES // 2    # 50% ceiling
ORACLE_RESERVE_BYTES = 1536 * 1024 * 1024           # 1.5 GiB reserve
CPU_CORES = os.cpu_count() or 4

# =============================================================================
# Collectors
# =============================================================================

def get_load_average():
    with open('/proc/loadavg') as f:
        return float(f.read().split()[0])

def get_memory_info():
    with open('/proc/meminfo') as f:
        content = f.read()
    mem_avail_kb = int([l for l in content.split('\n') if l.startswith('MemAvailable:')][0].split()[1])
    swap_free_kb = int([l for l in content.split('\n') if l.startswith('SwapFree:')][0].split()[1])
    return mem_avail_kb * 1024, swap_free_kb * 1024

def get_cpu_breakdown():
    # Single vmstat call
    result = subprocess.run(['vmstat', '1', '2'], capture_output=True, text=True, timeout=5)
    fields = result.stdout.strip().split('\n')[-1].split()
    return {
        'user': int(fields[12]),
        'system': int(fields[13]),
        'idle': int(fields[14]),
        'iowait': int(fields[15])
    }

def get_docker_stats():
    """Single docker stats call — returns (total_bytes, container_list)"""
    result = subprocess.run([
        'docker', 'stats', '--no-stream', '--no-trunc',
        '--format', '{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}'
    ], capture_output=True, text=True, timeout=10)

    multipliers = {
        'B': 1, 'KB': 1000, 'KiB': 1024,
        'MB': 1000000, 'MiB': 1048576,
        'GB': 1000000000, 'GiB': 1073741824,
    }

    total_bytes = 0
    containers = []

    if result.returncode != 0:
        return 0, []

    for line in result.stdout.strip().split('\n'):
        if not line:
            continue
        parts = line.split('|')
        if len(parts) < 4:
            continue
        name, cpu_pct, mem_usage, mem_pct = parts[0], parts[1], parts[2], parts[3]

        m = re.match(r'([0-9.]+)\s*([a-zA-Z]+)', mem_usage.strip())
        if m:
            num, unit = float(m.group(1)), m.group(2)
            total_bytes += num * multipliers.get(unit, 0)

        containers.append({
            'name': name,
            'status': '',
            'cpu': cpu_pct,
            'mem_usage': mem_usage,
            'mem_perc': mem_pct
        })

    return int(total_bytes), containers

def get_top_procs(sort_key='pcpu', n=5):
    """sort_key: 'pcpu' for CPU, 'rss' for memory"""
    result = subprocess.run(
        ['ps', 'aux', f'--sort=-{sort_key}', '--no-headers'],
        capture_output=True, text=True, timeout=5
    )
    procs = []
    for line in result.stdout.strip().split('\n')[:n]:
        parts = line.split(maxsplit=10)
        if len(parts) >= 11:
            procs.append({
                'pid': parts[1],
                'cpu': parts[2] if sort_key == 'pcpu' else parts[5],
                'mem_mb': parts[5] if sort_key == 'pcpu' else parts[2],
                'cmd': parts[10]
            })
    return procs

def determine_phase(load_percent, docker_percent, oracle_avail_bytes):
    if oracle_avail_bytes < 524288000 or load_percent >= 100 or docker_percent > 75:
        return 'PHASE-4'
    elif load_percent >= 80 or docker_percent > 60:
        return 'PHASE-3'
    elif load_percent >= 65 or docker_percent > 50:
        return 'PHASE-2'
    return 'PHASE-1'

# =============================================================================
# Main
# =============================================================================

def main():
    ts_local = datetime.now().strftime('%Y-%m-%d %I:%M %p %Z')
    ts_utc = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

    # Collect all metrics
    load_avg = get_load_average()
    mem_avail_bytes, swap_free_bytes = get_memory_info()
    cpu_breakdown = get_cpu_breakdown()
    docker_mem_bytes, containers = get_docker_stats()
    container_count = len(containers)

    # Derived
    load_percent = load_avg / CPU_CORES * 100
    docker_percent = docker_mem_bytes / DOCKER_CEILING_BYTES * 100 if DOCKER_CEILING_BYTES else 0
    mem_used_percent = (SYSTEM_MEMORY_BYTES - mem_avail_bytes) / SYSTEM_MEMORY_BYTES * 100
    docker_gib = docker_mem_bytes / 1073741824
    oracle_gib = mem_avail_bytes / 1073741824
    oracle_healthy = mem_avail_bytes >= ORACLE_RESERVE_BYTES
    docker_healthy = docker_mem_bytes <= DOCKER_CEILING_BYTES
    phase = determine_phase(load_percent, docker_percent, mem_avail_bytes)

    top_cpu = get_top_procs('pcpu')
    top_mem = get_top_procs('rss')

    # Build metrics dict
    metrics = {
        'timestamp': ts_utc,
        'timestamp_local': ts_local,
        'phase': phase,
        'system': {
            'hostname': 'ahie',
            'os': 'Linux 6.8.0-106-generic',
            'cpu_cores': CPU_CORES,
            'load_average_1m': round(load_avg, 2),
            'load_percent_of_cores': round(load_percent, 1),
            'cpu_breakdown': cpu_breakdown
        },
        'memory': {
            'total_bytes': SYSTEM_MEMORY_BYTES,
            'total_gib': round(SYSTEM_MEMORY_BYTES / 1073741824, 2),
            'available_bytes': mem_avail_bytes,
            'available_gib': round(oracle_gib, 2),
            'used_bytes': SYSTEM_MEMORY_BYTES - mem_avail_bytes,
            'oracle_available_bytes': mem_avail_bytes,
            'oracle_reserve_bytes': ORACLE_RESERVE_BYTES,
            'oracle_healthy': oracle_healthy,
            'swap_free_bytes': swap_free_bytes,
            'usage_percent': round(mem_used_percent, 1)
        },
        'docker': {
            'memory_used_bytes': int(docker_mem_bytes),
            'memory_used_gib': round(docker_gib, 2),
            'ceiling_bytes': DOCKER_CEILING_BYTES,
            'ceiling_gib': round(DOCKER_CEILING_BYTES / 1073741824, 1),
            'ceiling_percent_of_system': 50,
            'usage_percent_of_ceiling': round(docker_percent, 1),
            'healthy': docker_healthy,
            'container_count': container_count
        },
        'thresholds': {
            'docker_memory_ceiling_bytes': DOCKER_CEILING_BYTES,
            'intervention_load_percent': 65,
            'oracle_reserve_bytes': ORACLE_RESERVE_BYTES,
            'swap_policy': 'emergency_only'
        },
        'top_cpu_processes': top_cpu,
        'top_mem_processes': top_mem,
        'containers': containers
    }

    # Write metrics JSON
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(METRICS_FILE, 'w') as f:
        json.dump(metrics, f, indent=2)
    with open(LAST_METRICS_FILE, 'w') as f:
        json.dump(metrics, f, indent=2)

    # Append to markdown log
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    if not os.path.exists(LOG_FILE):
        with open(LOG_FILE, 'w') as f:
            f.write('# Metrics Log — Gibson\'s Workspace Manager\n\n')
            f.write('| Timestamp (EAT) | Phase | RAM%% | Docker%% | Load%% | Load Avg | Docker GiB | Oracle GiB | Notes |\n')
            f.write('|----------------|-------|------|---------|-------|----------|------------|------------|-------|\n')

    log_line = (f'| {ts_local} | {phase} | {mem_used_percent:.1f}% | '
                f'{docker_percent:.1f}% | {load_percent:.1f}% | {load_avg} | '
                f'{docker_gib:.2f} | {oracle_gib:.2f} | — |\n')
    with open(LOG_FILE, 'a') as f:
        f.write(log_line)

    print(f'[resource_monitor] {ts_local} | Phase: {phase} | '
          f'Docker: {docker_gib:.2f} GiB | Load: {load_avg} ({load_percent:.1f}%) | '
          f'Oracle: {oracle_gib:.2f} GiB free')

if __name__ == '__main__':
    main()
