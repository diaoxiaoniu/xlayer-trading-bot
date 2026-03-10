#!/bin/bash
# XLayer Trading Bot - Simple Version

WALLET="0x844e815218a78c2009b79ff778350e6cfe816df8"
TOKEN_ADDR="0xfdc4a45a4bf53957b2c73b1ff323d8cbe39118dd"
TOKEN_SYMBOL="TITAN"
USDC_ADDR="0x74b7f16337b8972027f6196a17a631ac6de26d22"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

get_price() {
    onchainos token price-info $TOKEN_ADDR --chain xlayer 2>/dev/null
}

get_balance() {
    onchainos portfolio all-balances --address $WALLET --chains xlayer 2>/dev/null
}

# Run
log "=== XLayer Trading Bot ==="
price_data=$(get_price)
balance_data=$(get_balance)

echo "$price_data" | python3 -m json.tool 2>/dev/null | head -20
echo "---BALANCE---"
echo "$balance_data" | python3 -m json.tool 2>/dev/null | head -30
