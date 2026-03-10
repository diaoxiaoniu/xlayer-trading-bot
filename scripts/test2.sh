#!/bin/bash
# XLayer Trading Bot

WALLET="0x844e815218a78c2009b79ff778350e6cfe816df8"
TOKEN="0xfdc4a45a4bf53957b2c73b1ff323d8cbe39118dd"
CHAIN="xlayer"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# Get price data
price_info=$(onchainos token price-info $TOKEN --chain $CHAIN 2>/dev/null)

# Parse with python
python3 << EOF
import json
import sys

try:
    data = json.loads('''$price_info''')
    if data.get('ok') and data.get('data'):
        d = data['data'][0]
        price = d.get('price', '0')
        min_price = d.get('minPrice', '0')
        max_price = d.get('maxPrice', '0')
        
        print(f"PRICE:{price}")
        print(f"LOW_24H:{min_price}")
        print(f"HIGH_24H:{max_price}")
    else:
        print("PRICE:0")
        print("LOW_24H:0")
        print("HIGH_24H:0")
except Exception as e:
    print(f"ERROR:{e}")
    print("PRICE:0")
    print("LOW_24H:0")
    print("HIGH_24H:0")
EOF
