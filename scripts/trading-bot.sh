#!/bin/bash
# XLayer Trading Bot - Automated trading with Discord notifications

# ========== CONFIG ==========
WALLET="0x844e815218a78c2009b79ff778350e6cfe816df8"
TOKEN="0xfdc4a45a4bf53957b2c73b1ff323d8cbe39118dd"
CHAIN="xlayer"
BUY_THRESHOLD=1.05
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1480968229420531723/XUypq8-w2eYVxu0Za-cOUfuuu4HukQALHo99Bsks69qKvdKwHehsutstjm4RQ7hPPt6E"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

discord() {
    curl -s -X POST "$DISCORD_WEBHOOK" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"$1\"}" >/dev/null 2>&1
}

get_data() {
    onchainos token price-info $TOKEN --chain $CHAIN 2>/dev/null
}

# Main
log "========== XLayer Trading Bot =========="

data=$(get_data)

python3 << EOF
import json

try:
    d = json.loads('''$data''')
    if d.get('ok') and d.get('data'):
        info = d['data'][0]
        price = float(info.get('price', '0') or '0')
        low_24h = float(info.get('minPrice', '0') or '0')
        high_24h = float(info.get('maxPrice', '0') or '0')
        
        print(f"Price: \${price:.4f}")
        print(f"24h Low: \${low_24h:.4f}")
        print(f"24h High: \${high_24h:.4f}")
        
        buy_thresh = low_24h * $BUY_THRESHOLD
        print(f"Buy Threshold: \${buy_thresh:.4f}")
        
        if price < buy_thresh:
            print("SIGNAL:BUY")
        else:
            print("SIGNAL:HOLD")
    else:
        print("Price: 0")
        print("SIGNAL:ERROR")
except Exception as e:
    print(f"Error: {e}")
    print("SIGNAL:ERROR")
EOF

log "=========================================="
