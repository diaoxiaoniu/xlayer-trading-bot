# XLayer Trading Bot

Automated trading bot for XLayer DEX using OKX Skills.

## Features

- 📊 **Price Monitoring** - Real-time price alerts
- 🤖 **Auto Trading** - Grid trading strategy  
- 📈 **Take Profit / Stop Loss** - Automatic exit
- 🔔 **Discord Notifications** - Trade alerts

## Setup

1. Install OKX Skills:
```bash
git clone https://github.com/okx/onchainos-skills.git
curl -sSL https://raw.githubusercontent.com/okx/onchainos-skills/main/install.sh | sh
```

2. Configure wallet:
Edit `config/config.env` with your wallet address

3. Run the bot:
```bash
bash scripts/trading-bot.sh
```

## Current Strategy

### Trading Pair: TITAN/USDC

| Parameter | Value |
|----------|-------|
| Entry | Price near 24h low + 5% |
| Take Profit | +30% |
| Stop Loss | -10% |

## Disclaimer

⚠️ Trading is risky. This bot is for educational purposes. Use at your own risk.
