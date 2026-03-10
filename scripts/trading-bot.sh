#!/bin/bash
# XLayer Trading Bot - With OKX API Auto Trade

export WALLET="${WALLET:-0x844e815218a78c2009b79ff778350e6cfe816df8}"
export DISCORD_WEBHOOK="${DISCORD_WEBHOOK_URL:-}"
export OKX_API_KEY="${OKX_API_KEY:-}"
export OKX_SECRET_KEY="${OKX_SECRET_KEY:-}"

TOKEN="0xfdc4a45a4bf53957b2c73b1ff323d8cbe39118dd"  # TITAN
USDC="0x74b7f16337b8972027f6196a17a631ac6de26d22"
CHAIN="xlayer"
BUY_AMOUNT="5000000"  # 5 USDC

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

discord() {
    if [ -n "$DISCORD_WEBHOOK" ]; then
        curl -s -X POST "$DISCORD_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"$1\"}" >/dev/null 2>&1
    fi
}

log "Fetching price data..."

price_info=$(onchainos token price-info $TOKEN --chain $CHAIN 2>/dev/null)

python3 << EOF
import json
import os
import subprocess

WEBHOOK = os.environ.get('DISCORD_WEBHOOK', '')
WALLET = os.environ.get('WALLET', '')
API_KEY = os.environ.get('OKX_API_KEY', '')
SECRET_KEY = os.environ.get('OKX_SECRET_KEY', '')
TOKEN = "$TOKEN"
USDC = "$USDC"
CHAIN = "$CHAIN"
BUY_AMOUNT = "$BUY_AMOUNT"

def send_discord(msg):
    if WEBHOOK:
        import urllib.request
        data = json.dumps({"content": msg}).encode('utf-8')
        req = urllib.request.Request(WEBHOOK, data=data, headers={'Content-Type': 'application/json'})
        try:
            urllib.request.urlopen(req)
        except:
            pass

def execute_swap():
    """Execute swap using OKX API"""
    if not API_KEY or not SECRET_KEY:
        return None, "No API keys"
    
    try:
        result = subprocess.run(
            ['onchainos', 'swap', 'swap',
             '--from', USDC,
             '--to', TOKEN,
             '--amount', BUY_AMOUNT,
             '--chain', CHAIN,
             '--wallet', WALLET],
            env={**os.environ, 'OKX_API_KEY': API_KEY, 'OKX_SECRET_KEY': SECRET_KEY},
            capture_output=True, text=True, timeout=60
        )
        return result.stdout, None
    except Exception as e:
        return None, str(e)

try:
    d = json.loads('''$price_info''')
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
            msg += "\nBUY SIGNAL!\n"
            
            # Get swap quote
            try:
                result = subprocess.run(
                    ['onchainos', 'swap', 'quote',
                     '--from', USDC,
                     '--to', TOKEN,
                     '--amount', BUY_AMOUNT,
                     '--chain', CHAIN],
                    capture_output=True, text=True, timeout=30
                )
                q_data = json.loads(result.stdout)
                if q_data.get('ok'):
                    q = q_data['data'][0]
                    msg += f"\nQuote (5 USDC -> TITAN):\n"
                    msg += f"  Output: {q.get('toTokenAmount', 'N/A')}\n"
                    msg += f"  Impact: {q.get('priceImpactPercent', 'N/A')}%\n"
                    
                    # Execute swap with API
                    if API_KEY and SECRET_KEY:
                        msg += "\nExecuting swap with OKX API...\n"
                        swap_result, swap_err = execute_swap()
                        if swap_err:
                            msg += f"Error: {swap_err}\n"
                        else:
                            swap_data = json.loads(swap_result)
                            if swap_data.get('ok'):
                                data = swap_data.get('data', [{}])[0]
                                if 'orderId' in data:
                                    msg += f"\n✅ ORDER PLACED! Order ID: {data['orderId']}\n"
                                elif 'txHash' in data:
                                    msg += f"\n✅ SWAP EXECUTED! Tx: {data['txHash'][:20]}...\n"
                                else:
                                    msg += f"\n✅ Swap Data: {str(data)[:100]}\n"
                            else:
                                msg += f"\nSwap Result: {swap_result[:200]}\n"
                    else:
                        msg += "\n⚠️ No API keys - cannot execute\n"
                else:
                    msg += f"\nQuote Error: {q_data.get('error', 'Unknown')}"
            except Exception as e:
                msg += f"\nError: {str(e)[:100]}"
        else:
            msg += "\nNo signal - price above threshold"
        
        print(msg)
        send_discord(msg)
    else:
        print("No price data")
        
except Exception as e:
    print(f"Error: {e}")
    send_discord(f"Error: {e}")

EOF
