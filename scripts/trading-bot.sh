#!/bin/bash
# XLayer Trading Bot - With Private Key Signing

export WALLET="${WALLET:-0x844e815218a78c2009b79ff778350e6cfe816df8}"
export DISCORD_WEBHOOK="${DISCORD_WEBHOOK_URL:-}"
export PRIVATE_KEY="${PRIVATE_KEY:-}"

TOKEN="0xfdc4a45a4bf53957b2c73b1ff323d8cbe39118dd"
USDC="0x74b7f16337b8972027f6196a17a631ac6de26d22"
CHAIN="xlayer"
BUY_AMOUNT="5000000"

# XLayer RPC (free public RPC)
RPC_URL="https://xlayer-rpc.okbtc.xyz"

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
from web3 import Web3

WEBHOOK = os.environ.get('DISCORD_WEBHOOK', '')
WALLET = os.environ.get('WALLET', '')
PRIVATE_KEY = os.environ.get('PRIVATE_KEY', '')
TOKEN = "0xfdc4a45a4bf53957b2c73b1ff323d8cbe39118dd"
USDC = "0x74b7f16337b8972027f6196a17a631ac6de26d22"
CHAIN = "xlayer"
BUY_AMOUNT = "5000000"
RPC_URL = "https://xlayer-rpc.okbtc.xyz"

def send_discord(msg):
    if WEBHOOK:
        import urllib.request
        data = json.dumps({"content": msg}).encode('utf-8')
        req = urllib.request.Request(WEBHOOK, data=data, headers={'Content-Type': 'application/json'})
        try:
            urllib.request.urlopen(req)
        except:
            pass

def sign_and_send_tx():
    if not PRIVATE_KEY or len(PRIVATE_KEY) < 32:
        return None, "Invalid private key"
    
    try:
        # Get swap tx data
        result = subprocess.run(
            ['onchainos', 'swap', 'swap', '--from', USDC, '--to', TOKEN,
             '--amount', BUY_AMOUNT, '--chain', CHAIN, '--wallet', WALLET],
            capture_output=True, text=True, timeout=60
        )
        
        data = json.loads(result.stdout)
        if not data.get('ok'):
            return None, f"Swap error: {data.get('error')}"
        
        tx_data = data['data'][0].get('tx', {})
        if not tx_data:
            return None, "No tx data"
        
        # Connect to RPC and sign
        w3 = Web3(Web3.HTTPProvider(RPC_URL))
        if not w3.is_connected():
            return None, f"Cannot connect to RPC: {RPC_URL}"
        
        account = w3.eth.account.from_key(PRIVATE_KEY)
        
        tx = {
            'to': tx_data.get('to'),
            'value': int(tx_data.get('value', '0'), 16) if isinstance(tx_data.get('value'), str) else tx_data.get('value', 0),
            'gas': int(tx_data.get('gas'), 16) if isinstance(tx_data.get('gas'), str) else tx_data.get('gas', 21000),
            'gasPrice': int(tx_data.get('gasPrice'), 16) if isinstance(tx_data.get('gasPrice'), str) else tx_data.get('gasPrice', w3.eth.gas_price),
            'nonce': w3.eth.get_transaction_count(account.address),
            'data': tx_data.get('data', '0x'),
            'chainId': 196
        }
        
        signed = account.sign_transaction(tx)
        tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
        
        return w3.to_hex(tx_hash), None
        
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
                    msg += "\nExecuting swap...\n"
                    tx_hash, err = sign_and_send_tx()
                    if err:
                        msg += f"Error: {err}\n"
                    else:
                        msg += f"\n✅ SWAP SUCCESS! Tx: {tx_hash}\n"
                else:
                    msg += "\n⚠️ No private key\n"
            else:
                msg += f"\nQuote error: {q_data.get('error')}\n"
        else:
            msg += "\nNo signal"
        
        print(msg)
        send_discord(msg)
    else:
        print("No price data")
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()

PYEOF
