#!/usr/bin/env python3
"""
Policy Engine — Gibson's Workspace Manager
Phase: Phase 2
Responsibility: Evaluate current state against WORKSPACE_RULES.md thresholds
Output: JSON with phase + recommended actions
"""
import json
import os
import sys

WORKSPACE = os.environ.get('WORKSPACE', '/root/.openclaw/workspace')
METRICS_FILE = os.path.join(WORKSPACE, 'workspace-manager/state/current_metrics.json')
PHASE_FILE = os.path.join(WORKSPACE, 'workspace-manager/state/current_phase.txt')

# Thresholds from WORKSPACE_RULES.md
ORACLE_RESERVE_BYTES = 1536 * 1024 * 1024   # 1.5 GiB
DOCKER_CEILING_BYTES = None                   # loaded from metrics

def load_metrics():
    if not os.path.exists(METRICS_FILE):
        return None
    with open(METRICS_FILE) as f:
        return json.load(f)

def determine_phase(docker_mem_bytes, docker_ceil_bytes, oracle_avail_bytes, load_percent):
    docker_pct = docker_mem_bytes / docker_ceil_bytes * 100 if docker_ceil_bytes else 0
    oracle_ok = oracle_avail_bytes >= ORACLE_RESERVE_BYTES

    if not oracle_ok or load_percent >= 100 or docker_pct > 75:
        return 'PHASE-4', docker_pct
    elif load_percent >= 80 or docker_pct > 60:
        return 'PHASE-3', docker_pct
    elif load_percent >= 65 or docker_pct > 50:
        return 'PHASE-2', docker_pct
    return 'PHASE-1', docker_pct

def recommended_actions(phase, docker_mem_bytes, docker_ceil_bytes):
    docker_pct = docker_mem_bytes / docker_ceil_bytes * 100 if docker_ceil_bytes else 0
    if phase == 'PHASE-1':
        return '[MONITOR] No action required'
    elif phase == 'PHASE-2':
        return '[ADVISORY] Clear logs, reduce Tier 4 restart frequency'
    elif phase == 'PHASE-3':
        return '[ACTIVE] Stop all Tier 4 containers, reduce Tier 3 memory limits'
    elif phase == 'PHASE-4':
        return '[EMERGENCY] Tier 1 only, emergency compact, notify Gibson'
    return '[UNKNOWN]'

def stop_list(phase):
    stop_map = {
        'PHASE-2': 'TIER4_REDUCE_RESTART',
        'PHASE-3': 'TIER4_STOP_ALL',
        'PHASE-4': 'TIER1_ONLY',
        'PHASE-1': 'NONE',
    }
    return stop_map.get(phase, 'NONE')

def main():
    d = load_metrics()
    if d is None:
        result = {'phase': 'UNKNOWN', 'error': 'No metrics file'}
        print(json.dumps(result, indent=2))
        sys.exit(1)

    docker_mem = d['docker']['memory_used_bytes']
    docker_ceil = d['thresholds']['docker_memory_ceiling_bytes']
    oracle_avail = d['memory']['oracle_available_bytes']
    load_pct = d['system']['load_percent_of_cores']

    phase, docker_pct = determine_phase(docker_mem, docker_ceil, oracle_avail, load_pct)
    prev_phase = os.path.exists(PHASE_FILE) and open(PHASE_FILE).read().strip() or 'UNKNOWN'

    # Write current phase
    with open(PHASE_FILE, 'w') as f:
        f.write(phase)

    result = {
        'phase': phase,
        'previous_phase': prev_phase,
        'metrics': {
            'docker_memory_bytes': docker_mem,
            'docker_ceiling_bytes': docker_ceil,
            'docker_percent_of_ceiling': round(docker_pct, 1),
            'load_percent_of_cores': load_pct,
            'load_average': d['system']['load_average_1m'],
            'cpu_cores': d['system']['cpu_cores'],
            'oracle_available_bytes': oracle_avail,
            'oracle_healthy': d['memory']['oracle_healthy'],
            'mem_used_percent': d['memory']['usage_percent'],
            'container_count': d['docker']['container_count']
        },
        'thresholds_check': {
            'docker_memory_within_ceiling': docker_mem <= docker_ceil,
            'load_within_threshold': load_pct < 65,
            'oracle_reserve_maintained': d['memory']['oracle_healthy']
        },
        'recommended_actions': recommended_actions(phase, docker_mem, docker_ceil),
        'stop_list': stop_list(phase),
        'phase_changed': phase != prev_phase
    }

    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    main()
