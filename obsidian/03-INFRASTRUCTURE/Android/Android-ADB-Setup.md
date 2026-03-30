# Android — ADB Setup

> **Last updated:** 2026-03-24 10:08 AM EAT
> **Status:** ❌ DISCONNECTED — No route to host

---

## 🔴 Current Problem

**2026-03-29 UPDATE: ✅ ADB CONNECTED VIA USB**

```
$ adb devices
List of devices attached
20429563B4043064	device
```

**Connection method:** USB (ADB over WiFi not working — "No route to host")
**Device ID:** 20429563B4043064
**Status:** SMS access ✅ working | Call log ⚠️ needs URI fix

---

## ✅ What ADB Unlocks When Connected

| Capability | Status |
|------------|--------|
| Read SMS (full inbox) | ✅ |
| Read M-PESA messages | ✅ |
| Read call logs | ✅ |
| Read notifications (content) | ⚠️ Needs permission |
| Read installed apps | ✅ |
| Access files | ✅ |
| Screen cast | ❌ Needs permission |
| Send SMS | ✅ |
| Make calls | ✅ |

---

## 🔧 How to Reconnect

### Option A: USB (Fastest)
1. Connect phone to host machine via USB
2. Enable USB debugging in Developer Options
3. Run: `adb devices` → should show device
4. Gibson grants trust prompt on phone

### Option B: WiFi ADB (No USB)
1. On phone: Developer Options → Enable ADB over network
2. Note the IP shown (usually 192.168.100.xxx)
3. On Oracle: `adb connect <phone-ip>:5555`
4. Grant trust on phone

### Option C: ZeroTier (Remote)
1. Ensure phone is on ZeroTier network
2. Find ZeroTier IP of phone
3. `adb connect <zt-ip>:5555`

---

## 📱 Known Devices

| Device | Last IP | Model | Android | Last Seen |
|--------|---------|-------|---------|-----------|
| V20 | 192.168.100.182 | LG V20 | Android 13 | 2026-03-23 20:25 EAT |

---

## 📋 M-PESA SMS Intelligence (from last session)

Gibson's M-PESA transactions captured via ADB:
- Multiple transfers to **erick omondi** (Ksh 90, 15, 100, 50)
- **Rebecca Moraa Ongeri:** Ksh 430 received (11/2)
- **RUFAS ATENG:** Ksh 530 SENT (11/2) — REVERSAL? Or payment?
- Airtime purchases: Ksh 20 today
- EcoBank: Account INACTIVE

---

## ⚠️ Next Steps

1. Gibson enables ADB over WiFi on phone (Developer Options)
2. Gibson shares the IP shown (or runs `adb connect` command)
3. Oracle reconnects and captures full SMS/notification history

---

*Oracle — Gibson's Second Brain | 2026-03-24*
