Last check: | 2026-03-31 09:03 | .6503 GiB | 5.00% | 0% | HEALTHY |
| 2026-03-31 02:02 alasiri EAT |  | 84.26% | 0% | 67.75% | 2.71 | 0.61 GiB | 1.94 GiB | — |
| 2026-03-31 02:09 alasiri EAT | PHASE-3 | 85.5% | 9.7% | 84.5% | 3.38 | 0.60 | 1.79 | — |
| 2026-03-31 02:14 alasiri EAT | PHASE-1 | 84.8% | 9.7% | 46.0% | 1.84 | 0.60 | 1.87 | — |
| 2026-03-31 02:14 alasiri EAT | PHASE-2 | 85.2% | 9.7% | 66.2% | 2.65 | 0.60 | 1.83 | — |
| 2026-03-31 02:18 alasiri EAT | PHASE-4 | 85.5% | 4399.3% | 84.2% | 3.37 | 271.70 | 1.79 | — |
| 2026-03-31 02:19 alasiri EAT | PHASE-4 | 85.4% | 4399.3% | 108.0% | 4.32 | 271.70 | 1.81 | — |
| 2026-03-31 02:21 PM  | PHASE-2 | 83.7% | 9.9% | 75.5% | 3.02 | 0.61 | 2.01 | — |
| 2026-03-31 02:22 PM  | PHASE-1 | 83.5% | 9.9% | 59.8% | 2.39 | 0.61 | 2.03 | — |
| 2026-03-31 02:22 PM  | PHASE-1 | 83.7% | 9.8% | 52.5% | 2.1 | 0.61 | 2.01 | — |
| 2026-03-31 02:24 PM  | PHASE-3 | 82.7% | 9.8% | 95.2% | 3.81 | 0.60 | 2.13 | — |
| 2026-03-31 02:25 PM  | PHASE-1 | 82.1% | 9.8% | 56.5% | 2.26 | 0.61 | 2.21 | — |
| 2026-03-31 05:11 PM  | PHASE-1 | 91.3% | 9.8% | 27.5% | 1.1 | 0.60 | 1.07 | — |
| 2026-03-31 05:11 PM  | PHASE-4 | 91.3% | 9.8% | 27.5% | 1.1 | 0.60 | 1.07 | Emergency compaction ran — stopped 4 containers (crypto_redis, crypto_prometheus, stack-duka-dao-app-1, trusting_beaver) |
| 2026-03-31 05:47 PM  | PHASE-1 | 90.5% | 8.5% | 52.0% | 2.08 | 0.52 | 1.17 | — |
| 2026-03-31 06:17 PM  | PHASE-1 | 90.9% | 8.1% | 43.2% | 1.73 | 0.50 | 1.12 | — |
| 2026-04-01 10:31 AM  | PHASE-1 | 42.5% | 16.8% | 55.5% | 2.22 | 1.03 | 7.11 | — |

## 2026-04-01 10:31 (EAT) — PHASE-1 ✅ HEALTHY
- **Docker:** 1.03 GiB
- **Load:** 2.22 (55.5%)
- **Oracle:** 7.11 GiB free
- **Phase Change:** PHASE-4 → PHASE-1 (load_or_memory_threshold)
- **Action:** No intervention needed
| 2026-04-02 08:56 AM  | PHASE-4 | 62.4% | 9.8% | 116.0% | 4.64 | 0.60 | 4.64 | — |


## 2026-04-02 08:56 (EAT) — PHASE-4 🚨 CRITICAL → Emergency Compaction Ran
- **Docker:** 0.60 GiB
- **Load:** 4.64 (116.0%) ⚠️
- **Oracle:** 4.64 GiB free
- **Phase Change:** PHASE-1 → PHASE-4 (load_or_memory_threshold)
- **Action:** Emergency compaction executed — stopped 4 containers
  - ✅ crypto_redis stopped
  - ✅ crypto_prometheus stopped
  - ✅ stack-duka-dao-app-1 stopped
  - ✅ trusting_beaver stopped
- **Top CPU culprit:** PID 1155328 (node) at 109% CPU
- **Notification:** Sent via workspace-manager notifier
| 2026-04-02 08:59 alasiri EAT | PHASE-4 | 62.4% | 9.8% | 116.0% | 4.64 | 0.60 | 4.64 | Emergency compaction ran — stopped 4 containers |
