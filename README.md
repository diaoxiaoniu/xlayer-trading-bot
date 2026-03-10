# XLayer Trading Bot

Automated crypto trading bot running on GitHub Actions.

## 📋 功能

- 🤖 自动交易策略 (网格交易)
- 📊 价格监控与信号检测
- 🔔 Discord 实时通知
- 💰 支持 XLayer DEX

## 🚀 快速开始

### 1. 配置 Secrets

在 GitHub 仓库 Settings → Secrets 中添加：

| Secret Name | 说明 |
|-------------|------|
| `DISCORD_WEBHOOK_URL` | Discord Webhook URL |
| `WALLET_ADDRESS` | 你的钱包地址 |

### 2. 运行工作流

工作流会自动每 5 分钟运行一次，也可以手动触发。

## 📁 文件结构

```
.
├── .github/
│   └── workflows/
│       └── trading.yml    # GitHub Actions 工作流
├── scripts/
│   └── trading-bot.sh     # 主交易脚本
├── config/
│   └── config.env         # 配置文件
└── README.md
```

## ⚠️ 风险提示

- 此机器人仅供学习交流
- 加密货币交易有风险
- 使用前请确保了解相关风险
- 建议先用小额测试
test
