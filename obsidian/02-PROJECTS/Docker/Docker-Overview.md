# Docker — Overview

> All containers running on ahie (192.168.100.182)

---

## ✅ Healthy Containers

| Container | Image | Ports | Status |
|-----------|-------|-------|--------|
| portainer | portainer/portainer-ce | :8000, :9443 | ✅ |
| stack-duka-dao-app | stack-duka-dao-app | :3000 | ✅ |
| bridge_api | bridge_stack-bridge-api | :3100 | ✅ |
| bridge_heartbeat | bridge_stack-bridge-heartbeat | :3101 | ✅ |
| bridge_tracker | bridge_stack-bridge-tracker | :3102 | ✅ |
| bridge_db | postgres:16-alpine | :5432 | ✅ |
| crypto-register-frontend | nginx:alpine | :10110 | ✅ |
| crypto_stack-options-bot | crypto_stack-options-bot | :5000 | ✅ |
| gibsons_dash | gibsons_dash | :10000 | ✅ |
| dao_wallet | dao_wallet | :5002 | ✅ |
| trusting_beaver | cloudflare/cloudflared | — | ✅ |
| zerotier | zyclonite/zerotier | — | ✅ |

---

## ⚠️ Unhealthy Containers

| Container | Status | Action |
|-----------|--------|--------|
| crypto_stack-resolver | ⚠️ UNHEALTHY | Investigate / restart |

---

## 🧠 Access Points

| Service | URL | Notes |
|---------|-----|-------|
| Portainer | https://192.168.100.182:9443 | Docker management |
| gibsons_dash | http://192.168.100.182:10000 | Gibson's dashboard |
| dao_wallet | http://192.168.100.182:5002 | DAO wallet |
| bridge_api | http://192.168.100.182:3100 | Bridge API |

---

## 🛡️ Security Notes

- Postfix SMTP (:25) on all interfaces — verify intentional
- MySQL on .122 exposed on LAN — ongoing risk
- Router telnet (.1:23) still open — ongoing risk
