# 📡 SamuSignal

**AI-Powered Forex & Crypto Signal App**

A Progressive Web App (PWA) for real-time forex and crypto trading signals with ADX indicator, 4H/Daily confluence filter, and trade tracker.

## 🚀 Live App

👉 [Open SamuSignal](https://YOUR-USERNAME.github.io/samusignal/Samusignal.html)

> Replace `YOUR-USERNAME` with your GitHub username after setup.

---

## 📱 Features

- **Signal Cards** — BUY / SELL / WAIT signals for 8 major pairs
- **ADX Indicator** — Trend strength meter with +DI / -DI
- **4H & Daily Confluence Filter** — Only shows high-probability setups
- **Market Overview** — 12 pairs with ADX column
- **Trade Tracker** — Add trades, track P&L, Breakeven, Trailing Stop
- **Alerts Tab** — Signal history log
- **Trading Gyaan** — Daily trading tips (Hindi)
- **PWA Install** — Install as mobile app on Android & iOS
- **Offline Support** — Works without internet (Service Worker)
- **TwelveData API** — Live price integration (optional)

---

## 📁 Files

| File | Description |
|------|-------------|
| `Samusignal.html` | Main app — open this in browser |
| `manifest.json` | PWA manifest for mobile install |
| `sw.js` | Service Worker — offline + caching |
| `icon-192.png` | App icon (192×192) |
| `icon-512.png` | App icon (512×512) |

---

## ⚙️ Setup

### GitHub Pages (Free Hosting)

1. Upload all files to a new GitHub repo
2. Go to **Settings → Pages**
3. Source: **Deploy from branch → main → / (root)**
4. Save → Your app will be live in ~1 minute

### TwelveData API (Optional — for live prices)

1. Get free API key at [twelvedata.com](https://twelvedata.com) (800 calls/day free)
2. Open the app → tap **⚙ API** → paste your key → Save

---

## 📊 Indicators Used

| Indicator | Description |
|-----------|-------------|
| **RSI (14)** | Overbought/Oversold detection |
| **MACD** | Trend momentum |
| **EMA 20 / 50** | Trend direction |
| **ADX (14)** | Trend strength — >25 = valid trend |
| **+DI / -DI** | Bullish vs Bearish pressure |
| **4H Confluence** | Higher timeframe bias check |
| **Daily Confluence** | Daily trend alignment |

---

## 📲 Mobile Install (PWA)

**Android (Chrome):**
- Open app → tap **⬇ Install App** button at top
- Or: Chrome menu → "Add to Home Screen"

**iPhone (Safari):**
- Open app in Safari
- Tap Share button → "Add to Home Screen"

---

## 📜 Disclaimer

This app is for **educational purposes only**. Signals are based on technical indicators and do not guarantee profit. Always use proper risk management and consult a financial advisor before trading.

---

Made with ❤️ | SamuSignal v2.0
