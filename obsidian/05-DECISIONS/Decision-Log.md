# 05 — Decisions

> Major decisions with trade-off analysis. Gibson's decision log.

---

## 📋 Decision Framework

When a major decision is needed, I work through:

1. **What's the goal?** (Define clearly)
2. **What are the options?** (Usually 2-3)
3. **What's the cost of each?** (Time, money, complexity)
4. **What's reversible?** (Can we change course later?)
5. **What's the worst case?** (Is it survivable?)
6. **Oracle's take:** (Honest read with recommendation)

---

## 🗂️ Past Decisions

### 2026-03-21: Keep Malicious Cron Job or Remove It?

**Situation:** Cron job "Oracle" was found running a script that attempted ADB extraction of call logs, SMS, and voice recordings. No data was extracted (script was erroring).

**Options:**
- Remove the cron job immediately
- Analyze first, then remove
- Report to Gibson before any action

**Decision:** Remove immediately ✅
**Oracle's take:** No brainer. The job was malicious. Removed immediately. Documented the incident.

---

### 2026-03-21: OpenClaw Configuration — Leave as-is or Reconfigure?

**Situation:** Channels (Telegram, WhatsApp, Email) not configured. OpenRouter rate limited. Discord not set up.

**Options:**
- Spend time configuring all channels now (hours of setup)
- Leave as-is and focus on highest ROI (MoltChain ecosystem)
- Configure only the fastest channel (Telegram — 30 min)

**Decision:** Focus on MoltChain (highest ROI) + defer channel config
**Oracle's take:** Right call. Channel config is important but MoltChain is the business. One cron job keeps the ecosystem growing while channels remain a manual setup when Gibson has time.

---

### 2026-03-20: Run Daily Network Scan Cron or Pause It?

**Situation:** Cron job for network scan was erroring due to OpenRouter rate limit.

**Options:**
- Kill the cron (stop bleeding)
- Switch the model to avoid rate limits
- Lower the frequency

**Decision:** Lower frequency + switch model (work in progress)
**Status:** Still rate-limited. Need to check OpenRouter billing.
**Oracle's take:** The scan is valuable for security. Fix the rate limit issue by checking billing or switching to a non-metered model.

---

## 🚨 Pending Decisions

| Decision | Urgency | Blocker |
|----------|---------|---------|
| OpenRouter billing — continue or switch model? | 🟡 Medium | Gibson needs to check dashboard |
| Microservices cron — kill or try to fix? | 🔴 High | 49 errors, wasting resources |

---

## 💡 How Oracle Helps

When Gibson faces a tough decision, he should tell me:
- What's the situation
- What he's leaning toward
- What's worrying him

I'll respond with:
- Options clearly laid out
- Honest assessment of each
- My recommendation (if asked)

---

*Last updated: 2026-03-22*
