# 🌐 Network Infrastructure — Updated 2026-04-09

> Gibson's home network: 192.168.100.0/24
> Gateway: 192.168.100.1 (Huawei)
> Server: ahie (192.168.100.182)

---

## 📍 LAN Device Map (Evening Scan — Apr 9, 8:24 PM EAT)

| IP | Device | MAC Vendor | Key Services | Status |
|----|--------|------------|--------------|--------|
| .1 | Huawei Router (gateway) | Huawei | telnet 23 ⚠️, DNS 53, HTTP 80/443 | ⚠️ telnet OPEN |
| .4 | LG Smart TV | 60:8D:26 | port 3000 | ✅ **RETURNED** Apr 9 — was gone since Apr 5 |
| .104 | **Unknown** | 8A:83:61 | port 49152 (tcpwrapped) | ⚠️ **NEW Apr 9** — investigate |
| .105 | TP-Link device | F4:F2:6D | all filtered | 🔒 |
| .116 | D-Link device | 78:54:2E | all filtered | 🔒 |
| .122 | Bitsoko Server | CC:32:E5 | SSH 22, HTTP 80, Samba 139/445, MySQL 3306, Abyss 9999 | ⚠️ |
| .182 | ahie (this host) | — | SSH 22, SMTP 25, DNS 53, HTTP 80, Docker | ✅ |
| .251 | Unknown | 7E:E3:F5 | port 49152 (tcpwrapped) | ⚠️ RETURNED Apr 9 |
| .253 | **Unknown** | 52:AF:EF | all ports closed | ⚠️ **NEW Apr 9** — investigate |

---

## 📊 Device Status Summary

**Active:** 9 devices (up from 7 last week)

**Returned:**
- `.4` LG Smart TV — back after ~4 days offline ✅
- `.251` Unknown — returned after morning absence

**New:**
- `.104` Unknown — port 49152 open (MAC 8A:83:61:00:5E:38)
- `.253` Unknown — all ports closed (MAC 52:AF:EF:87:F3:C5)

**Gone (still):**
- `.21` TP-Link — gone since Apr 8
- `.23` TP-Link/SZ Teleone — gone since Apr 9 AM
- `.33` Nagios host — gone since Apr 5 PM

---

## 🔌 Services Running on This Host (:182)

| Service | Port | Status |
|---------|------|--------|
| SSH | 22 | ✅ OpenSSH 8.9p1 |
| SMTP | 25 | ✅ Postfix |
| DNS | 53 | ✅ BIND 9.18.39 |
| HTTP | 80 | ✅ Duka DAO (Node.js/Express) |
| Kong Proxy | 8000 | ✅ Microservices gateway |
| Kong Admin | 8001 | ✅ |
| Keycloak | 8180 | ✅ Keycloak (Quarkus) |
| Consul | 8500 | ✅ Service mesh |
| Elasticsearch | 9200 | ✅ Search/analytics |
| Kibana | 5601 | ✅ Visualization |
| Kafka | 9092 | ✅ Message broker |
| Zookeeper | 2181 | ✅ |
| Redis | 6379 | ✅ Cache |
| Prometheus | 9090 | ✅ Metrics |
| Grafana | 3000 | ✅ Dashboards |
| Portainer | 9443 | ✅ Docker management |
| Ollama | 11434 | ✅ LLM inference |
| netdata | 19999 | ✅ Monitoring |
| Tor | 9050 | ✅ Anonymity |
| ZeroTier | 9993 | ✅ VPN |

---

## 🌐 External Access

- **ZeroTier:** VPN mesh network (was on 10.144.180.80/16)
- **Cloudflare Tunnels:** Public services exposed via CF
- **Kong API Gateway:** `/paylife` → service-c, `/service-a` → service-a

---

## ⚠️ Security Issues (Priority Order)

| Issue | Severity | Fix |
|-------|----------|-----|
| Router telnet :23 open 52+ days | 🔴 CRITICAL | Disable via 192.168.100.1 admin panel |
| `.104` new unknown device | 🟡 MEDIUM | Investigate MAC 8A:83:61:00:5E:38 |
| `.253` new unknown device | 🟡 LOW | Investigate MAC 52:AF:EF:87:F3:C5 |
| MySQL on .122 LAN exposed | 🟡 MEDIUM | Firewall or bind to localhost |
| `.122` Abyss port 9999 | 🟡 MEDIUM | Investigate service |

---

## 📋 Docker Stacks on ahie

**All running on 192.168.100.182:**

| Stack | Containers | Status |
|-------|------------|--------|
| **Microservices Stack** | 17 (consul, kong, keycloak, kafka, elasticsearch, etc.) | ✅ ALL UP |
| **Bridge Stack** | 4 (bridge_api, bridge_db, bridge_heartbeat, bridge_tracker) | ✅ ALL UP |
| **Crypto Stack** | 4 (crypto_nginx, crypto_loki, crypto_prometheus, crypto_grafana) | ✅ ALL UP |

**Microservices location:** `/home/africool/Documents/microservices/microservices-stack/`

---

*Last updated: 2026-04-09 8:24 PM EAT | Oracle*
