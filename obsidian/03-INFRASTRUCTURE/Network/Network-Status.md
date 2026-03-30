# 🌐 Network Infrastructure

> Gibson's home network: 192.168.100.0/24
> Gateway: 192.168.100.1 (Huawei)
> Server: ahie (192.168.100.182)

---

## 📍 LAN Device Map

| IP | Device | Notes |
|----|--------|-------|
| 192.168.100.1 | Huawei Gateway | Router, telnet port 23 OPEN ⚠️ |
| 192.168.100.100 | Unknown | Device .100 — unidentified |
| 192.168.100.138 | Unknown | NEW — appeared Sunday, MAC: C8:54:A4:57:DF:A1 ⚠️ |
| 192.168.100.182 | ahie (THIS HOST) | Gibson's server — Docker, ZeroTier, Cloudflare |
| 192.168.100.??? | Android V20 | Gibson's phone — ADB connected (was) |

---

## 🔌 Services Running

| Service | Port | Status | Notes |
|---------|------|--------|-------|
| Docker | 2375? | ⚠️ Exposed? | Need to verify |
| MySQL | 3306 | ⚠️ LAN exposed | .122 — security risk |
| Portainer | 9000? | Need check | Docker management |
| Cloudflare Tunnel | Various | ✅ Running | Public access |
| ZeroTier | 9993 | ✅ Running | VPN mesh |
| Traefik | 80/443 | ✅ Running | Reverse proxy |
| Prometheus | 9090 | ✅ Running | Metrics |

---

## 🌐 External Access

- **ZeroTier:** Managed VPN mesh network
- **Cloudflare Tunnels:** Public services exposed via CF tunnels
- **Traefik:** Internal reverse proxy for docker-compose stacks

---

## ⚠️ Security Issues

| Issue | Severity | Fix |
|-------|----------|-----|
| Router telnet :23 open | 🔴 HIGH | Disable telnet on Huawei gateway |
| Unknown device .138 | 🟡 MEDIUM | Investigate MAC C8:54:A4:57:DF:A1 |
| MySQL on .122 LAN exposed | 🟡 MEDIUM | Firewall or bind to localhost |
| Docker daemon exposed? | 🟡 MEDIUM | Check if 2375/2376 open |

---

## 📊 Docker Stacks

All running on ahie (192.168.100.182):

```
crypto_stack/          — Blockchain resolver + options bot
bridge/                — Bridge API + DB + heartbeat + tracker
stack-duka/            — DAO app
gibsons_dash/          — Gibson's monitoring
dao_wallet/            — Governance wallet
trusting_beaver/       — (unknown purpose)
zerotier-one/          — VPN mesh
```

---

*Last updated: 2026-03-23*
