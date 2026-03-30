#!/bin/bash
# Cloudflare Domain Management CLI
# Usage: cfdomain <command> [args]

set -e

CF_API="https://api.cloudflare.com/client/v4"
CF_ZONE="db955cdb4beae180b8d02ed1ef3e4395"
CF_ACCOUNT="ccbfcc017fa4dae58c5057cee0428b99"
CF_TOKEN_FILE="${CLOUDFLARE_API_TOKEN_FILE:-$HOME/.cloudflare-api-token}"

usage() {
    cat <<EOF
Usage: cfdomain <command> [args]

Commands:
  dns list                        List all DNS records
  dns get <name>                  Get DNS record by name
  dns add <type> <name> <content>  Add DNS record
  dns update <id> <content>       Update DNS record content
  dns delete <id>                 Delete DNS record
  tunnel status                   Show tunnel health
  tunnel restart                  Restart Linux cloudflared tunnel
  ssl                             Show SSL/TLS settings
  zone settings                   Show all zone settings

Examples:
  cfdomain dns list
  cfdomain dns add A mamaduka 192.168.100.182
  cfdomain dns add CNAME www mamaduka.africoolinc.com
  cfdomain tunnel status
EOF
}

get_token() {
    if [[ -f "$CF_TOKEN_FILE" ]]; then
        TOKEN=$(cat "$CF_TOKEN_FILE" | tr -d '\n')
    else
        echo "Error: API token not found at $CF_TOKEN_FILE" >&2
        echo "Set CLOUDFLARE_API_TOKEN_FILE or create ~/.cloudflare-api-token" >&2
        exit 1
    fi
}

api() {
    get_token
    curl -s "$CF_API/$1" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        "$2"
}

cmd_dns_list() {
    api "zones/$CF_ZONE/dns_records" | python3 -m json.tool 2>/dev/null || api "zones/$CF_ZONE/dns_records"
}

cmd_dns_get() {
    local name="$1"
    api "zones/$CF_ZONE/dns_records?name=$name&type=A" | python3 -m json.tool 2>/dev/null || api "zones/$CF_ZONE/dns_records?name=$name"
}

cmd_dns_add() {
    local type="$1" name="$2" content="$3"
    [[ -z "$type" || -z "$name" || -z "$content" ]] && { echo "Usage: cfdomain dns add <type> <name> <content>"; exit 1; }
    api "zones/$CF_ZONE/dns_records" -X POST -d "{\"type\":\"$type\",\"name\":\"$name\",\"content\":\"$content\",\"ttl\":3600}"
}

cmd_dns_delete() {
    local id="$1"
    [[ -z "$id" ]] && { echo "Usage: cfdomain dns delete <id>"; exit 1; }
    api "zones/$CF_ZONE/dns_records/$id" -X DELETE
}

cmd_tunnel_status() {
    echo "=== Linux Host Tunnel ==="
    if systemctl is-active cloudflared &>/dev/null; then
        echo "Status: active (systemd)"
        curl -s http://127.0.0.1:20250/metrics 2>/dev/null | grep -E "cloudflared_tunnel_ha_connections|connection_errors" | python3 -m json.tool 2>/dev/null || \
        curl -s http://127.0.0.1:20250/metrics 2>/dev/null | grep "cloudflared_tunnel"
    else
        echo "Status: inactive"
    fi
    echo ""
    echo "=== MacBook Tunnel ==="
    if kill -0 6160 2>/dev/null; then
        echo "Status: running (PID 6160)"
    else
        echo "Status: not running"
    fi
}

cmd_tunnel_restart() {
    echo "Restarting cloudflared..."
    systemctl restart cloudflared
    sleep 3
    cmd_tunnel_status
}

cmd_ssl() {
    api "zones/$CF_ZONE/settings/ssl" | python3 -m json.tool 2>/dev/null
}

cmd_zone_settings() {
    api "zones/$CF_ZONE/settings" | python3 -m json.tool 2>/dev/null
}

COMMAND="${1:-}"
shift || true

case "$COMMAND" in
    dns)
        SUBCMD="${1:-}"
        shift || true
        case "$SUBCMD" in
            list) cmd_dns_list "$@" ;;
            get) cmd_dns_get "$@" ;;
            add) cmd_dns_add "$@" ;;
            delete) cmd_dns_delete "$@" ;;
            *) usage; exit 1 ;;
        esac
        ;;
    tunnel)
        SUBCMD="${1:-}"
        shift || true
        case "$SUBCMD" in
            status) cmd_tunnel_status "$@" ;;
            restart) cmd_tunnel_restart "$@" ;;
            *) usage; exit 1 ;;
        esac
        ;;
    ssl) cmd_ssl "$@" ;;
    zone) cmd_zone_settings "$@" ;;
    *) usage; exit 1 ;;
esac
