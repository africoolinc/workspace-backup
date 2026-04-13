# Docker — Overview

> All containers running on ahie (192.168.100.182) | **Updated: 2026-04-09**

---

## 🐳 Microservices Stack — 17 Containers ✅

**Location:** `/home/africool/Documents/microservices/microservices-stack/`
**Start:** `cd /home/africool/Documents/microservices/microservices-stack && docker compose up -d`
**Logs:** `docker compose logs -f`

| Container | Image | Ports | Status |
|-----------|-------|-------|--------|
| consul | consul:1.15 | 8500 | ✅ |
| kong | kong:3.4 | 8000, 8001 | ✅ |
| kong-db | postgres:14 | 5432 | ✅ |
| keycloak | quay.io/keycloak | 8180 | ✅ |
| keycloak-db | postgres:15 | 5432 | ✅ |
| app-db | postgres:16 | 5432 | ✅ |
| redis | redis:7 | 6379 | ✅ |
| zookeeper | confluentinc/cp-zookeeper | 2181 | ✅ |
| kafka | confluentinc/cp-kafka | 9092, 29092 | ✅ |
| prometheus | prom/prometheus | 9090 | ✅ |
| grafana | grafana/grafana | 3000 | ✅ |
| elasticsearch | docker.elastic.co/elasticsearch | 9200, 9300 | ✅ |
| kibana | docker.elastic.co/kibana | 5601 | ✅ |
| logstash | docker.elastic.co/logstash | 5044 | ✅ |
| service-a | service-a | 5001 | ✅ |
| service-b | service-b | 5002 | ✅ |
| service-c | service-c | 5003 | ✅ **PayLife UI** |

### PayLife Fintech UI (service-c)
**URL:** `http://192.168.100.182:8000/paylife/`
**Pages:** Dashboard, Login, Send Money, Statements, Wallet
**Kong route:** `/paylife` → `service-c:5000`

### Keycloak Admin
**URL:** `http://192.168.100.182:8180/admin/`
**Credentials:** `admin / adminpass`

---

## 🌉 Bridge Stack — 4 Containers ✅

| Container | Image | Ports | Status |
|-----------|-------|-------|--------|
| bridge_api | bridge_stack-bridge-api | 3100 | ✅ |
| bridge_heartbeat | bridge_stack-bridge-heartbeat | 3101 | ✅ |
| bridge_tracker | bridge_stack-bridge-tracker | 3102 | ✅ |
| bridge_db | postgres:16-alpine | 5432 | ✅ |

---

## 💰 Crypto Stack — 4 Containers ✅

| Container | Image | Ports | Status |
|-----------|-------|-------|--------|
| crypto_nginx | nginx:alpine | 80, 443 | ✅ |
| crypto_loki | grafana/loki | 3100 | ✅ |
| crypto_prometheus | prom/prometheus | 9090 | ✅ |
| crypto_grafana | grafana/grafana | 3000 | ✅ |

---

## 📦 Other Containers

| Container | Image | Ports | Status |
|-----------|-------|-------|--------|
| portainer | portainer/portainer-ce | 8000, 9443 | ✅ |
| zerotier | zyclonite/zerotier | 9993 | ✅ |
| trusting_beaver | cloudflare/cloudflared | — | ✅ |
| gibsons_dash | gibsons_dash | 10000 | ✅ |
| dao_wallet | dao_wallet | 5002 | ✅ |

**Total containers:** 22+ across 3 stacks

---

## 🛡️ Security Notes

| Issue | Severity | Status |
|-------|----------|--------|
| Router telnet (.1:23) OPEN | 🔴 CRITICAL | 52+ days |
| MySQL on .122 LAN exposed | 🟡 MEDIUM | Ongoing |
| Postfix SMTP (:25) open | 🟡 | Verify intentional |
| Docker daemon 2375/2376 | 🟡 | Check firewall |

---

## 🔧 Management Commands

```bash
# Microservices
cd /home/africool/Documents/microservices/microservices-stack
docker compose up -d        # Start
docker compose logs -f      # Watch logs
docker compose ps           # Status

# Health check
bash /root/.openclaw/workspace/microservices_stack/monitor.sh

# Portainer
https://192.168.100.182:9443

# Docker prune (disk cleanup)
docker image prune -a -f
docker container prune -f
```

---

*Last updated: 2026-04-09 8:31 PM EAT | Oracle*
