# Backup & Security Strategy — Gibson's Workspace

> Last updated: 2026-03-30

---

## Overview

Automated daily backup and security scanning for Gibson's OpenClaw workspace, including Android/Termux integration, Docker state snapshots, encrypted archives, and GitHub sync.

**GitHub:** `https://github.com/africoolinc/workspace-backup`
**Backup script:** `/root/bin/workspace-backup.sh`
**Backup dir:** `/root/.backups/`

---

## Backup Schedule

| Cron | Name | Time | What it does |
|------|------|------|--------------|
| `0 3 * * *` | Daily Workspace Backup | 3:00 AM EAT | Full backup + GitHub push |
| `0 6 * * *` | Daily Security Scan | 6:00 AM EAT | Security log review + alert |

---

## What Gets Backed Up

### 1. Workspace Files
Archive of `/root/.openclaw/workspace/`:
- `AGENTS.md`, `IDENTITY.md`, `MEMORY.md`, `SOUL.md`, `USER.md`, `TOOLS.md`
- `HEARTBEAT.md`, `WORKSPACE_RULES.md`
- `obsidian/` — Second brain mind map
- `memory/` — Daily session logs
- `skills/` — Custom skills (nmap-scan, cloudflare-domain, wireshark-scan)
- `workspace-manager/` — Resource monitoring logs
- `crypto_stack/` — Docker compose + config (NOT secrets)
- `android_logs/` — ADB SMS/Call logs
- `sim-diagnostics/` — SIM probe data

### 2. Docker State
- `docker-state-YYYY-MM-DD.json` — all container states, volumes, networks
- `portainer-db-YYYY-MM-DD.db` — Portainer SQLite DB snapshot

### 3. Android/Termux (via ADB)
- Termux home directory (if `--debug` granted and accessible)
- SMS monitor logs
- ADB device status snapshot

### 4. Encrypted Archives
- `secrets-YYYY-MM-DD.tar.gz.enc` — AES-256 encrypted: TOOLS.md, MEMORY.md, crypto_stack/.env
- Encryption password: stored in `/root/.backup-enc-pass`

### 5. Security Scan
- `security-YYYY-MM-DD.log` — Cron jobs, network listeners, Docker status, secret exposure check, open ports

---

## GitHub Sync

**Repo:** `https://github.com/africoolinc/workspace-backup`
**Token:** `YOUR_GITHUB_TOKEN`
**Branch:** `master`

Files pushed:
- All workspace files (source, not archives)
- Latest `workspace-YYYY-MM-DD.tar.gz`
- Latest `docker-state-YYYY-MM-DD.json`
- Latest `security-YYYY-MM-DD.log`
- Latest `adb-status-YYYY-MM-DD.txt`

---

## Retention Policy

| Type | Retention |
|------|-----------|
| Archives (tar.gz) | 7 days |
| Portainer DBs | 7 days |
| Encrypted files | 14 days |
| Logs | 7 days |
| Android backups | 7 days |

---

## Security Layers

### Input Filtering
- All external content (web pages, API responses) parsed and sanitized
- System injection markers stripped automatically

### Secret Redaction
- Scripts scan for exposed API keys, tokens, passwords in workspace files
- Sensitive files encrypted at rest with AES-256

### Approval Gate
- External outputs (Discord posts, emails) require explicit user approval
- Announce mode sends results to webchat for review

### Secrets Management
- Real credentials stored in `crypto_stack/.env` (NOT in git)
- API tokens in `~/.cloudflare-global-api-key`, `~/.cloudflare-api-token`
- Encryption passwords in `~/.backup-enc-pass`

---

## Auto-Checks Schedule

| Frequency | Check | Tool |
|-----------|-------|------|
| Daily 3 AM | Full backup + GitHub sync | workspace-backup.sh |
| Daily 6 AM | Security scan review | workspace-backup.sh |
| Every 5 min | Resource monitoring | resource_check.sh |
| Every 30 min | Docker health watch | workspace-manager |
| Every 2 hours | MoltChain engagement | MOLTCHAIN cron |
| Every 3 hours | SIM probe | sim_probe_host.sh |
| Every 5 min | Android SMS monitor | sms_monitor.sh |

---

## Troubleshooting

### GitHub push fails
```bash
# Check repo exists
curl -s https://api.github.com/repos/africoolinc/workspace-backup
# Re-clone if needed
rm -rf /root/.workspace-git-clone
# Re-run backup
/root/bin/workspace-backup.sh
```

### Encryption fails
```bash
# Set encryption password
echo "your-password" > /root/.backup-enc-pass
chmod 600 /root/.backup-enc-pass
# Test
tar -czf - files | openssl enc -aes-256-cbc -pbkdf2 -salt -pass file:/root/.backup-enc-pass -out /tmp/test.enc
```

### ADB/Termux access fails
```bash
# Re-authorize ADB on Android
adb kill-server
adb start-server
adb devices  # should show device with "unauthorized"
# On Android: approve USB debugging prompt, check "Always allow from this computer"
```

### Backup not running
```bash
# Check cron status
systemctl status cron 2>/dev/null || systemctl status systemd-cron 2>/dev/null
# Check next run
grep -A5 "workspace-backup" /root/.openclaw/workspace/MEMORY.md 2>/dev/null | head -20
# Manual run
/root/bin/workspace-backup.sh 2>&1 | tail -20
```

---

## Restoring from Backup

```bash
# 1. Clone repo
git clone https://github.com/africoolinc/workspace-backup.git /tmp/restore
cd /tmp/restore

# 2. Extract workspace
tar -xzf workspace-$(ls -1 workspace-*.tar.gz | head -1 | sed 's/workspace-//;s/.tar.gz//').tar.gz -C /root/.openclaw/workspace/

# 3. Decrypt secrets (if needed)
openssl enc -aes-256-cbc -pbkdf2 -d -salt \
    -pass file:/root/.backup-enc-pass \
    -in secrets-YYYY-MM-DD.tar.gz.enc \
    -out /tmp/secrets.tar.gz
tar -xzf /tmp/secrets.tar.gz -C /root/.openclaw/workspace/
```
