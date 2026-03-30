# 06 — Knowledge: Tools Reference

> Oracle's capabilities and limits. What I can and can't do.

---

## 🔧 What Oracle Can Do

### Core Capabilities
- **Read/write files** — Full filesystem access on the host
- **Run shell commands** — Docker, system tools, scripts
- **Web search** — Brave API (needs API key)
- **Web fetch** — Read content from URLs
- **Browser control** — Take screenshots, automate web flows
- **Cron jobs** — Schedule recurring tasks
- **Network scanning** — nmap for LAN reconnaissance
- **Docker management** — Inspect containers, logs, health
- **Read memory files** — Context from previous sessions
- **TTS** — Text-to-speech via ElevenLabs

### Android Integration (ADB)
- **SMS** — Read inbox and conversations
- **Call logs** — History, missed calls, durations
- **Files** — Pull photos, downloads from phone
- **Notifications** — Read current notifications (needs app)
- **Camera** — Take photos or screenshots
- **Location** — GPS coordinates
- **App management** — Install/uninstall apps

### Messaging (Channels not yet configured)
- Telegram (planned)
- WhatsApp (planned)
- Discord (planned)
- Email (planned)

---

## ❌ What Oracle Can't Do (Yet)

| Capability | Blocker |
|------------|---------|
| Read texts | ADB not connected |
| Read emails | No email channel configured |
| Read WhatsApp | WhatsApp channel not configured |
| Read Telegram | Telegram channel not configured |
| Moltbook write ops | Dashboard not set up |
| Discord MoltChain | Bot token missing |
| Web search | Brave API key missing |

---

## 🧠 Oracle's Thinking Process

**Default mode:** Fast, direct, practical.

**When to think harder:**
- Multi-step technical problems
- Security-sensitive decisions
- Things that affect Gibson's privacy
- Ecosystem strategy (MoltChain)

**When to escalate:**
- Anything that modifies safety settings
- External actions (emails, posts, messages)
- Destructive commands (rm, truncate)
- Decisions Gibson should make himself

---

## 📁 Key Files I Reference

| File | What It Contains |
|------|-----------------|
| `MEMORY.md` | Long-term curated memory |
| `memory/YYYY-MM-DD.md` | Daily session logs |
| `obsidian/00-*.md` | Current blueprint mind map |
| `TOOLS.md` | Environment-specific config |
| `USER.md` | Gibson's profile and preferences |

---

## ⚡ Speed vs. Thoroughness

| Task | Approach |
|------|----------|
| Quick questions | Direct answer, no fanfare |
| Technical problems | Try, then ask if stuck |
| Security decisions | Think first, act second |
| Ecosystem strategy | Thorough, surface options |
| Routine tasks | Automate via cron |

---

*Last updated: 2026-03-22*
