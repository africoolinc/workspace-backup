---
name: cloudflare-domain
description: Manage Cloudflare-hosted domains (DNS, tunnels, SSL, zone settings). Use when working with Cloudflare DNS, cloudflared tunnels, SSL certificates, or domain configuration for africoolinc.com and subdomains like mamaduka.africoolinc.com.
---

# Cloudflare Domain Management

## Identity
- **Account ID:** `ccbfcc017fa4dae58c5057cee0428b99`
- **Zone ID:** `db955cdb4beae180b8d02ed1ef3e4395`
- **Primary domain:** `africoolinc.com`
- **Key subdomain:** `mamaduka.africoolinc.com`

## API Setup

**API Token** stored in `~/.cloudflare-api-token` (create with permission: Zone:DNS:Edit, Tunnel:Edit).

```bash
# Save token
echo "your-api-token" > ~/.cloudflare-api-token
chmod 600 ~/.cloudflare-api-token
```

**Base curl:**
```bash
CF_API="https://api.cloudflare.com/client/v4"
CF_ZONE="db955cdb4beae180b8d02ed1ef3e4395"
CF_ACCOUNT="ccbfcc017fa4dae58c5057cee0428b99"
CF_TOKEN=$(cat ~/.cloudflare-api-token)
HEADERS="-H 'Authorization: Bearer $CF_TOKEN' -H 'Content-Type: application/json'"
```

## DNS Management

### List DNS records
```bash
curl -s "$CF_API/zones/$CF_ZONE/dns_records" $HEADERS | python3 -m json.tool
```

### Create DNS record
```bash
curl -s -X POST "$CF_API/zones/$CF_ZONE/dns_records" \
  $HEADERS -d '{"type":"A","name":"HOSTNAME","content":"IP","ttl":3600}'
```

### Update DNS record
```bash
curl -s -X PUT "$CF_API/zones/$CF_ZONE/dns_records/RECORD_ID" \
  $HEADERS -d '{"type":"A","name":"HOSTNAME","content":"IP","ttl":3600}'
```

### Delete DNS record
```bash
curl -s -X DELETE "$CF_API/zones/$CF_ZONE/dns_records/RECORD_ID" $HEADERS
```

### DNS record types
- `A` — IPv4 address
- `AAAA` — IPv6 address  
- `CNAME` — alias to another domain
- `TXT` — text records (verification, SPF, DKIM, DMARC)
- `MX` — mail servers

## Tunnel Management

### Tunnel token format (decoded)
```
{"a":"ACCOUNT_ID","t":"TUNNEL_ID","s":"SECRET"}
```

### Active tunnels on this host
- **Linux host tunnel:** PID 2851394, protocol=http2, connections=4 (jnb01 + cpt01)
  - Token: `872edd4b-54dd-47b5-b468-678fd0b2c551`
- **MacBook host tunnel:** PID 6160, running on MacBook Pro
  - Token: `2c995659-7d0a-4ef8-b9af-8aa4a37b0237`

### Restart Linux tunnel
```bash
systemctl restart cloudflared
# or manual:
cloudflared --config ~/.cloudflared/config.yml tunnel run
```

### Health check
```bash
curl -s http://127.0.0.1:20250/metrics | grep cloudflared_tunnel_ha_connections
# Should show: cloudflared_tunnel_ha_connections 4
```

## DNS for `mamaduka.africoolinc.com`

Point subdomain to cloudflared tunnel's public hostname:
```bash
# 1. Get tunnel's CNAME (from Cloudflare dashboard or tunnel logs)
# 2. Create CNAME record:
curl -s -X POST "$CF_API/zones/$CF_ZONE/dns_records" \
  $HEADERS -d '{
    "type":"CNAME",
    "name":"mamaduka",
    "content":"TUNNEL_CNAME_SUBDOMAIN.cf-tunnel.com",
    "ttl":3600,
    " proxied":true
  }'
```

## SSL/TLS Settings

Check SSL mode:
```bash
curl -s "$CF_API/zones/$CF_ZONE/settings/ssl" $HEADERS
```

Full zone settings:
```bash
curl -s "$CF_API/zones/$CF_ZONE/settings" $HEADERS | python3 -m json.tool
```

## Cloudflare Docs
- API v4: https://developers.cloudflare.com/api/
- DNS API: https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-dns-record
- Tunnel: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
