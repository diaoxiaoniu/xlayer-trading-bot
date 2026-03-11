#!/bin/bash
# XLayer Trading Bot - Using OKX Gateway for broadcast

export WALLET="${WALLET:-0x844e815218a78c2009b79ff778350e6cfe816df8}"
export DISCORD_WEBHOOK="${DISCORD_WEBHOOK_URL:-}"
export PRIVATE_KEY="${PRIVATE_KEY:-}"

TOKEN="0xfdc4a45a4bf53957b2c73b1ff323d8cbe39118dd"
USDC="0x74b7f16337b8972027f6196a17a631ac6de26d22"
CHAIN="xlayer"
BUY_AMOUNT="5000000"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

discord() {
    if [ -n "$DISCORD_WEBHOOK" ]; then
        curl -s -X POST "$DISCORD_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"$1\"}" >/dev/null 2>&1
    fi
}

log "Fetching price data..."
onchainos token price-info $TOKEN --chain $CHAIN > /tmp/price.json 2>/dev/null

python3 << 'PYEOF'
import json
import os
import subprocess

WEBHOOK = os.environ.get('DISCORD_WEBHOOK', '')
WALLET = os.environ.get('WALLET', '')
PRIVATE_KEY = os.environ.get('PRIVATE_KEY', '')
TOKEN = "0xfdc4a45a4bf53957b2c73b1ff323d8cbe39118dd"
USDC = "0x74b7f16337b8972027f6196a17a631ac6de26d22"
CHAIN = "xlayer"
BUY_AMOUNT = "5000000"

def send_discord(msg):
    if WEBHOOK:
        import urllib.request
        data = json.dumps({"content": msg}).encode('utf-8')
        req = urllib.request.Request(WEBHOOK, data=data, headers={'Content-Type': 'application/json'})
        try:
            urllib.request.urlopen(req)
        except:
            pass

def get_swap_and_broadcast():
    if not PRIVATE_KEY or len(PRIVATE_KEY) < 32:
        return None, "No private key"
    
    try:
        # Get swap transaction data
        result = subprocess.run(
            ['onchainos', 'swap', 'swap', '--from', USDC, '--to', TOKEN,
             '--amount', BUY_AMOUNT, '--chain', CHAIN, '--wallet', WALLET],
            capture_output=True, text=True, timeout=60
        )
        
        data = json.loads(result.stdout)
        if not data.get('ok'):
            return None, f"Swap error: {data.get('error')}"
        
        # Try gateway broadcast
        result2 = subprocess.run(
            ['onchainos', 'gateway', 'broadcast', '--signed-tx', result.stdout, '--address', WALLET, '--chain', CHAIN],
            capture_output=True, text=True, timeout=60
        )
        
        return result2.stdout, None
        
    except Exception as e:
        return None, str(e)

try:
    with open('/tmp/price.json') as f:
        d = json.load(f)
    
    if d.get('ok') and d.get('data'):
        info = d['data'][0]
        price = float(info.get('price', '0') or '0')
        low_24h = float(info.get('minPrice', '0') or '0')
        high_24h = float(info.get('maxPrice', '0') or '0')
        change_24h = float(info.get('priceChange24H', '0') or '0')
        
        buy_thresh = low_24h * 1.05
        
        msg = f"XLayer Trading Bot\n"
        msg += f"TITAN: ${price:.4f}\n"
        msg += f"24h: {change_24h:+.2f}%\n"
        msg += f"Range: ${low_24h:.4f} - ${high_24h:.4f}\n"
        msg += f"Buy Threshold: ${buy_thresh:.4f}\n"
        
        if price < buy_thresh:
            msg += "\nBUY SIGNAL!\n"
            
            # Get quote
            result = subprocess.run(
                ['onchainos', 'swap', 'quote', '--from', USDC, '--to', TOKEN,
                 '--amount', BUY_AMOUNT, '--chain', CHAIN],
                capture_output=True, text=True, timeout=30
            )
            q_data = json.loads(result.stdout)
            if q_data.get('ok'):
                q = q_data['data'][0]
                msg += f"\nQuote (5 USDC -> TITAN):\n"
                msg += f"  Output: {q.get('toTokenAmount', 'N/A')}\n"
                msg += f"  Impact: {q.get('priceImpactPercent', 'N/A')}%\n"
                
                if PRIVATE_KEY and len(PRIVATE_KEY) > 32:
                    msg += "\nTrying to broadcast...\n"
                    broadcast_result, err = get_swap_and_broadcast()
                    if err:
                        msg += f"Error: {err}\n"
                    else:
                        msg += f"Result: {broadcast_result[:200]}\n"
                else:
                    msg += "\n⚠️ No private key\n"
            else:
                msg += f"\nQuote error\n"
        else:
            msg += "\nNo signal"
        
        print(msg)
        send_discord(msg)
    else:
        print("No price data")
except Exception as e:
    print(f"Error: {e}")

PYEOF
