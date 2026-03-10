#!/bin/bash
# XLayer Trading Bot

export WALLET="${WALLET:-0x844e815218a78c2009b79ff778350e6cfe816df8}"
export DISCORD_WEBHOOK="${DISCORD_WEBHOOK_URL:-}"

TOKEN="0xfdc4a45a4bf53957b2c73b1ff323d8cbe39118dd"
CHAIN="xlayer"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

discord() {
    if [ -n "$DISCORD_WEBHOOK" ]; then
        curl -s -X POST "$DISCORD_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"$1\"}" >/dev/null 2>&1
    fi
}

log "Fetching price data..."

data=$(onchainos token price-info $TOKEN --chain $CHAIN 2>/dev/null)

python3 << EOF
import json
import os

WEBHOOK = os.environ.get('DISCORD_WEBHOOK', '')

def send_discord(msg):
    if WEBHOOK:
        import urllib.request
        data = json.dumps({"content": msg}).encode('utf-8')
        req = urllib.request.Request(
            WEBHOOK,
            data=data,
            headers={'Content-Type': 'application/json'}
        )
        try:
            urllib.request.urlopen(req)
        except:
            pass

try:
    d = json.loads('''$data''')
    if d.get('ok') and d.get('data'):
        info = d['data'][0]
        price = float(info.get('price', '0') or '0')
        low_24h = float(info.get('minPrice', '0') or '0')
        high_24h = float(info.get('maxPrice', '0') or '0')
        change_24h = float(info.get('priceChange24H', '0') or '0')
        
        buy_thresh = low_24h * 1.05
        
        msg = "XLayer Trading Bot\n"
        msg += f"TITAN: \${price:.4f}\n"
        msg += f"24h: {change_24h:+.2f}%\n"
        msg += f"Range: \${low_24h:.4f} - \${high_24h:.4f}\n"
        msg += f"Buy Threshold: \${buy_thresh:.4f}\n"
        
        if price < buy_thresh:
            msg += "\nBUY SIGNAL!"
        else:
            msg += "\nNo signal"
        
        print(msg)
        send_discord(msg)
    else:
        print("No data")
        
except Exception as e:
    print(f"Error: {e}")
    send_discord(f"Error: {e}")
EOF
